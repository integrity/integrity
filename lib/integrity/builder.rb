module Integrity
  class Builder
    extend Scheduler

    attr_reader :build, :logger

    def self.scheduler_wait
      wait_t = Integrity.config.scheduler_wait_for_fleet_time
      Integrity.logger.debug "sleeping for scheduler_wait_for_fleet_time=#{wait_t}s"
      sleep(wait_t)
    end

    def self.scheduler_select_machine(nickname=nil, machine_id=nil)
      machine = machine_id ? Integrity.cluster.select_machine_for_build : Integrity.cluster.select_machine_for_build_with_id(machine_id)
      Integrity.logger.debug "#{nickname || 'selected'} machine=#{machine}"
    end

    def self.start_build(build)
      scheduler_wait
      first_inquiry_machine = scheduler_select_machine(:first_inquiry)

      if build.started?
        log_build(:start_build, build, "not running because build started already, in #{build.status} state")
      elsif first_inquiry_machine.nil?
        log_build(:start_build, build, "not running because there are no machines with build capacity")
      else
        scheduler_wait
        verified_machine = scheduler_select_machine(:verified)

        if verified_machine
          log "verified scheduled machine ip=#{verified_machine.ip}"
          log_build(:start_build, build, "Clear builds on branch: #{build.branch_name}") { Integrity::Event.trigger('branch:cleanup', build.id) }
          log_build(:start_build, build, "Running build"){ launch_build(build, verified_machine) }
        else
          log_build(:start_build, build, "not running because the first_inquiry machine(id=#{first_inquiry_machine.id} capacity=#{first_inquiry_machine.capacity}) " +
                    "did not have capacity after the scheduler_wait_for_fleet_time")
        end
      end
    end

    # Keep Queuing Builds until we have reached the threashhold.
    # Try to queue all pending builds.
    def self.queue_builds!
      log "queue_builds: - #{Build.pending.count} builds pending. Attempting to queue remaining builds..."
      Build.pending.map do |b|
        log_build(:queue_builds, b, :queueing) { b.run }
      end
    end

    # Launches the passed build on fleet. Before starting, it kills
    # older builds from same branch (and itself if it was a re-run)
    def self.launch_build(build, scheduled_machine)
      log_execution(:launch_build, build) do
        log_build(:launch_build, build, :cleanup) { Integrity.cluster.destroy_build(build.service_options) }
        log_build(:launch_build, build, "starting on worker ip=#{scheduled_machine.ip} id=#{scheduled_machine.id}") do
          Integrity.cluster.start_build(build.service_options, scheduled_machine.id)
        end
        log_build(:launch_build, build, :started) { build.reload.started! }
        log_build(:launch_build, build, 'Updating fleet'){ Build.update_fleetctl_status }
      end
    end

    # Kill fleet unit and destroy service matching build that was passed.
    def self.destroy_build(build)
      log_execution(:destroy_build, build){ Integrity.cluster.destroy_build(build.service_options) }
    end

    def self.log_execution(action, build)
      log_build action, build, 'starting'
      yield
      log_build action, build, 'completed'
    end

    def self.log_build(action, build, msg)
      log "#{action}: [Build:#{build.try(:id)}] (#{build.service_vars.inspect}) - #{msg}"
      yield if block_given?
    end

    def self.log(msg)
      msg = "[Integrity::Builder]: #{msg}"
      Integrity.logger.info msg
    end
  end
end
