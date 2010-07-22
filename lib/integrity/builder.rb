module Integrity
  class Builder
    def self.build(_build, logger)
      new(_build, logger).build
    end

    def initialize(build, logger)
      @build  = build
      @logger = logger
      @status = false
      @output = ""
    end

    def build
      start
      run_command
      complete
      notify
    end

    def start
      @logger.info "Started building #{repo.uri} at #{commit}"
      checkout.checkout
      @build.update(:started_at => Time.now, :commit => checkout.metadata)
    end

    def run_command
      @status, @output = checkout.run_in_dir(command)
    end

    def complete
      @logger.info "Build #{commit} exited with #{@status} got:\n #{@output}"

      @build.update(
        :completed_at => Time.now,
        :successful   => @status,
        :output       => @output
      )
    end

    def notify
      @build.project.enabled_notifiers.each { |n| n.notify(@build) }
    end

    def checkout
      @checkout ||= Checkout.new(repo, commit, directory, @logger)
    end

    def directory
      @directory ||= Integrity.config.directory.join(@build.id.to_s)
    end

    def repo
      @build.project.repo
    end

    def command
      @build.project.command
    end

    def commit
      @build.sha1
    end
  end
end
