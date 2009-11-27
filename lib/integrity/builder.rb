module Integrity
  class Builder
    def initialize(build)
      @build = build
    end

    def build
      scm.with_commit(@build.commit.identifier) { |commit|
        started(scm.metadata(commit))
        completed(*run)
      }
    end

    def started(metadata)
      Integrity.log "Started building %s at %s" % [@build.project.uri,
        metadata["identifier"]]

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

    def completed(status, output)
      Integrity.log "Completed build %s. Exited with %s, got:\n %s" % [
        @build.commit.identifier, status, output]

      @build.update!(
        :completed_at   => Time.now,
        :successful     => status,
        :output         => output
      )

      @build.project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end

    def run
      output = ""
      status = false

      IO.popen(script, "r") { |io| output = io.read }
      status = $?.success?

      [status, output]
    end

    def script
      "(cd #{scm.dir_for(@build.commit.identifier)} && " \
        "#{@build.project.command} 2>&1)"
    end

    def scm
      @scm ||= SCM.new(@build.project.scm, @build.project.uri,
        @build.project.branch)
    end
  end
end
