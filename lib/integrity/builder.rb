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
      start
      run
      complete
      notify
    end

    def start
      @logger.info "Started building #{repo.uri} at #{commit}"
      checkout.run
      @build.update(:started_at => Time.now, :commit => checkout.metadata)
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
