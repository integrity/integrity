module Integrity
  class Builder

    attr_reader :build, :logger

    def self.start_build(build)
      # Get number of running builds.
      running = Build.running(:count)

      # Only launch build if the number of running builds hasn't reached the limit.
      unless running >= Integrity.max_running_builds
        name = build.project.permalink
        sha  = build.sha1_short

        Integrity.launch_build(name, sha)
        build.update(started_at: Time.now)
      end
    end

    def self.queue_next_build
      # Get first pending build (fifo).
      pending = Build.pending(:first)

      # If there are any pending builds, start the first one.
      start_build(pending) if pending.present?
    end

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
