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
      repo.checkout(commit)
      start
      run
      complete
    end

    def start
      Integrity.log "Started building #{@build.project.uri} at #{commit}"

      metadata = repo.metadata(commit)

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
      IO.popen(script, "r") { |io| @output = io.read }
      @status = $?.success?
    end

    def script
      "(cd #{repo.dir_for(commit)} && #{@build.project.command} 2>&1)"
    end

    def repo
      @repo ||= Repository.new(@build.project.uri, @build.project.branch)
    end

    def commit
      @build.commit.identifier
    end
  end
end
