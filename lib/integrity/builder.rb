module Integrity
  class Builder

    attr_reader :build, :logger

    # Only launch build if the number of running builds hasn't reached the limit.
    def self.start_build(build)
      # this if stmt is the source the branch cleanup behavior bug
      if build.started?
        log_build(:start_build, build, "not running because build started already, in #{build.status} state")
      elsif at_capacity?
        log_build(:start_build, build, "not running because Integrity is at capacity")
      else
        log_build(:start_build, build, "Clear builds on branch: #{build.branch_name}") { Integrity::Event.trigger('branch:cleanup', build.id) }
        log_build(:start_build, build, "Running build"){ launch_build(build) }
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
    def self.launch_build(build)
      log_execution(:launch_build, build) do
        if build.uses_swarm
          log "using swarm"
          log_build(:launch_build, build, :cleanup) { build.destroy_containers }
          log_build(:launch_build, build, :starting){ build.run_containers }
        else
          log "using fleet"
          log_build(:launch_build, build, :cleanup) { Integrity.cluster.destroy_build(build) }
          log_build(:launch_build, build, :starting){ Integrity.cluster.start_build(build) }
        end
        log_build(:launch_build, build, :started) { build.reload.started! }
      end
    end

    # Kill fleet unit and destroy service matching build that was passed.
    def self.destroy_build(build)
      if build.uses_swarm
        log_execution(:destroy_build, build){ build.destroy_containers }
      else
        log_execution(:destroy_build, build){ Integrity.cluster.destroy_build(build) }
      end
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

    #According to this, 4 tp builds would be 'at capacity'.  This is probably an artifact, we can discuss later
    def self.at_capacity?
      running   = Build.running(:count)
      run_limit = Integrity.config.run_limit
      log "at_capacity?: #{running} out of #{run_limit} builds running."
      running >= run_limit
    end
  end
end
