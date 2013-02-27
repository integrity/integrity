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
      @logger.info "Started building #{repo.uri} at #{commit}"
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
      @build.update(:output => @build.output + chunk)
    end
    
    def complete
      @logger.info "Build #{commit} exited with #{@result.success} got:\n #{@result.output}"

      @build.raise_on_save_failure = true
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
      
      @build.raise_on_save_failure = true
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
