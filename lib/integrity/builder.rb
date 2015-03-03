module Integrity
  class Builder

    attr_reader :build, :logger

    # Only launch build if the number of running builds hasn't reached the limit.
    def self.start_build(build)
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
        log_build(:launch_build, build, :cleanup) { Crust.destroy(build.service_options) }
        log_build(:launch_build, build, :starting){ Crust.start(build.service_options) }
        log_build(:launch_build, build, :started) { build.reload.started! }
        log_build(:launch_build, build, 'Updating fleet'){ Build.update_fleetctl_status }
      end
    end

    # Kill fleet unit and destroy service matching build that was passed.
    def self.destroy_build(build)
      log_execution(:destroy_build, build){ Crust.destroy(build.service_options) }
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
      Integrity.sys_logger(:delayed_job).info msg
    end

    #According to this, 4 tp builds would be 'at capacity'.  This is probably an artifact, we can discuss later
    def self.at_capacity?
      running   = Build.running(:count)
      run_limit = 4
      log "at_capacity?: #{running} out of #{run_limit} builds running."
      running >= run_limit
    end

    # Dead code
    # If there are any pending builds, start the first one.
    def self.queue_next_build
      log "queue_next_build - #{Build.pending.count} builds pending. Queueing next build..."
      Build.pending.first.try(:run)
    end

    # Dead code
    def self.cleanup_orphans
      Build.orphaned.each do |build|
        log_build(:cleanup_orphans, build, "Orphaned! Running for #{build.human_run_time}. Stopping."){ destroy_build(build) }
      end
    end

    #### OLD INTEGRITY METHODS - NOT USED ANYMORE
    #############################################

    def self.build(_build, directory, logger)
      new(_build, directory, logger).build
    end

    def self.docker(_build, directory, logger)
      new(_build, directory, logger).build_docker_image
    end

    def initialize(build, directory, logger)
      @build     = build
      @directory = directory
      @logger    = logger
    end

    def build
      begin
        start
        run do |chunk|
          add_output(chunk)
        end
      rescue Interrupt, SystemExit
        raise
      rescue Exception => e
        fail(e)
      else
        complete
      end
      notify
    end

    def start
      logger.info "start - starting #{repo.uri} at #{commit}"
      @build.raise_on_save_failure = true
      @build.update(:started_at => Time.now)
      @build.project.enabled_notifiers.each { |n| n.notify_of_build_start(@build) }
      checkout.run
      # checkout.metadata invokes git and may fail
      @build.commit.raise_on_save_failure = true
      @build.commit.update(checkout.metadata)
      logger.info "start completed #{repo.uri} at #{commit}"
    end

    def run
      @result = checkout.run_in_dir(command) do |chunk|
        yield chunk
      end
    end

    def add_output(chunk)
      @build.update(output: @build.output + chunk)
    end
    
    def complete
      logger.info "[fi] Build #{commit} exited with #{@result.success} got:\n #{@result.output}"
      @build.raise_on_save_failure = true
      @build.complete!(@result)
    end
    
    def fail(exception)
      failure_message = "#{exception.class}: #{exception.message}"
      failure_message << "\n\n"
      exception.backtrace.each do |line|
        failure_message << line << "\n"
      end

      logger.info "[builder][fail][fi] with message #{failure_message}. Setting as complete."
      @build.set_as_complete!(false)
    end

    def notify
      @build.notify
    end

    def checkout
      @checkout ||= Checkout.new(repo, commit, directory, logger)
    end

    def directory
      @_directory ||= @directory.join(@build.id.to_s)
    end

    def repo
      @build.repo
    end

    def command
      @build.command
    end

    def commit
      @build.sha1
    end

    def docker_start
      logger.info "Started building #{repo.uri} at #{commit}"
      @build.raise_on_save_failure = true
      @build.update(started_at: Time.now)
      @build.project.enabled_notifiers.each {|n| n.notify_of_build_start(@build) }
      # checkout.metadata invokes git and may fail
      # @build.commit.raise_on_save_failure = true
      # @build.commit.update(checkout.metadata)
    end

    def build_docker_image
      begin
        docker_start
        docker = Docker.new(repo, commit, directory, logger)
        docker.build!
        result = docker.run(:mysql) do |chunk|
          add_output(chunk)
          logger.debug chunk
        end
        logger.info "MySQL Running: #{result.success}"
        logger.info "MySQL ContainerID: #{result.output}"
        @result = docker.run(:image) do |chunk|
          add_output(chunk)
          logger.debug chunk
        end
        if @result.output.blank?
          @result = docker.run(:image) do |chunk|
            add_output(chunk)
            logger.debug chunk
          end
        end
      rescue Interrupt, SystemExit
        raise
      rescue Exception => e
        fail(e)
      else
        complete
      end
      notify
    end

    private

    def run_cmd(cmd)
      checkout.run_in_dir(cmd) do |chunk|
        add_output(chunk)
      end
    end

  end
end
