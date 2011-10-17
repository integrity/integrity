module Integrity
  class Builder
    def self.build(_build, directory, logger)
      new(_build, directory, logger).build
    end

    def initialize(build, directory, logger)
      @build     = build
      @directory = directory
      @logger    = logger
    end

    def build
      begin
        start
        run
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
      @logger.info "Started building #{repo.uri} at #{commit}"
      @build.update(:started_at => Time.now)
      @build.project.enabled_notifiers.each { |n| n.notify_of_build_start(@build) }
      # checkout.metadata invokes git and may fail
      @build.update(:commit => checkout.metadata)
      checkout.run
    end

    def run
      @result = checkout.run_in_dir(command)
    end

    def complete
      @logger.info "Build #{commit} exited with #{@result.success} got:\n #{@result.output}"

      @build.update(
        :completed_at => Time.now,
        :successful   => @result.success,
        :output       => @result.output
      )
    end
    
    def fail(exception)
      failure_message = "#{exception.class}: #{exception.message}"
      
      @logger.info "Build #{commit} failed with an exception: #{failure_message}"
      
      failure_message << "\n\n"
      exception.backtrace.each do |line|
        failure_message << line << "\n"
      end
      
      @build.update(
        :completed_at => Time.now,
        :successful => false,
        :output => failure_message
      )
    end

    def notify
      @build.notify
    end

    def checkout
      @checkout ||= Checkout.new(repo, commit, directory, @logger)
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
  end
end
