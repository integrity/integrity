module Integrity
  class Builder
    def self.build(b)
      new(b).build
    end

    def initialize(build)
      @build  = build
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
      Integrity.logger.info "Started building #{@build.project.uri} at #{commit}"
      checkout.checkout
      @build.update(:started_at => Time.now, :commit => checkout.metadata)
    end

    def run_command
      @status, @output = checkout.run(command)
    end

    def complete
      Integrity.logger.info "Build #{commit} exited with #{@status} got:\n #{@output}"

      @build.update(
        :completed_at => Time.now,
        :successful   => @status,
        :output       => @output
      )
    end

    def notify
      @build.project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end

    def checkout
      @checkout ||= Checkout.new(
        repo,
        commit,
        checkout_directory
      )
    end

    def checkout_directory
      @dir ||= Integrity.config.directory.join(@build.id.to_s)
    end

    def repo
      @build.project.repo
    end

    def command
      @build.project.command
    end

    def commit
      @build.commit.identifier
    end
  end
end
