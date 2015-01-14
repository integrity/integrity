module Integrity
  class Builder

    attr_reader :build, :logger

    # Only launch build if the number of running builds hasn't reached the limit.
    def self.start_build(build)
      running   = Build.running(:count)
      run_limit = Integrity.max_running_builds
      log "Checking build queue: #{running} out of #{run_limit} builds running."
      launch_build(build) if running < run_limit
    end

    # Keep Queuing Builds until we have reached the threashhold.
    # Try to queue all pending builds.
    def self.queue_builds!
      log "#{Build.pending.count} builds pending. Attempting to queue remaining builds..."
      Build.pending.map{|b| b.run }
    end

    # If there are any pending builds, start the first one.
    def self.queue_next_build
      log "#{Build.pending.count} builds pending. Queueing next build..."
      Build.pending.first.try(:run)
    end

    # Launches the passed build on fleet. Before starting, it kills
    # older builds from same branch (and itself if it was a re-run)
    def self.launch_build(build)
      log "Launching Build: #{build.service_vars.inspect}"
      build.cleanup!
      # build.rebuild ? build.cleanup! : build.kill_previous_builds!
      Crust.start(*build.service_vars)
      build.started!
      log "#{Build.running.count} builds running."
    end

    # Kill fleet unit and destroy service matching build that was passed.
    def self.destroy_build(build)
      log "Destroying Build: #{build.service_vars.inspect}"
      Crust.destroy(*build.service_vars)
    end

    def self.log(msg)
      Integrity.logger.info msg
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
      logger.info "Started building #{repo.uri} at #{commit}"
      @build.raise_on_save_failure = true
      @build.update(:started_at => Time.now)
      @build.project.enabled_notifiers.each { |n| n.notify_of_build_start(@build) }
      checkout.run
      # checkout.metadata invokes git and may fail
      @build.commit.raise_on_save_failure = true
      @build.commit.update(checkout.metadata)
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
      logger.info "Build #{commit} exited with #{@result.success} got:\n #{@result.output}"
      @build.raise_on_save_failure = true
      @build.complete!(@result)
    end
    
    def fail(exception)
      failure_message = "#{exception.class}: #{exception.message}"
      
      logger.info "Build #{commit} failed with an exception: #{failure_message}"
      
      failure_message << "\n\n"
      exception.backtrace.each do |line|
        failure_message << line << "\n"
      end
      
      @build.raise_on_save_failure = true
      @build.fail!(failure_message)
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
