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
      run
      complete
    end

    def start
      Integrity.log "Started building #{@build.project.uri} at #{commit}"

      checkout.run

      metadata = checkout.metadata

      @build.update(
        :started_at => Time.now,
        :commit     => {
          :identifier   => metadata["id"],
          :message      => metadata["message"],
          :author       => metadata["author"],
          :committed_at => metadata["timestamp"]
        }
      )
    end

    def complete
      Integrity.log "Build #{commit} exited with #{@status} got:\n #{@output}"

      @build.update!(
        :completed_at => Time.now,
        :successful   => @status,
        :output       => @output
      )

      @build.project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end

    def run
      cmd = "(cd #{checkout_directory} && #{@build.project.command} 2>&1)"
      IO.popen(cmd, "r") { |io| @output = io.read }
      @status = $?.success?
    end

    def checkout
      @checkout ||= Checkout.new(
        @build.project.uri,
        @build.project.branch,
        commit,
        checkout_directory
      )
    end

    def checkout_directory
      @dir ||= Integrity.config.directory.join(@build.id.to_s)
    end

    def commit
      @build.commit.identifier
    end
  end
end
