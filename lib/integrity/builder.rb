module Integrity
  class BuildableProject
    def self.call(buildable)
      return [] unless project = Project.first(
        :scm      => buildable["scm"],
        :uri.like => "#{buildable["uri"]}%",
        :branch   => buildable["branch"]
      )
      buildable["commits"].collect { |c| new(project, c["id"]) }
    end

    def initialize(project, commit)
      @project = project
      @commit  = commit
    end

    def build
      b = @project.builds.create(:commit => {:identifier => @commit})
      Integrity.config.builder.build(b)
      b
    end
  end

  class Builder < Bob::Builder
    def initialize(buildable)
      @build = buildable

      super(
        "scm"     => @build.project.scm,
        "uri"     => @build.project.uri.to_s,
        "branch"  => @build.project.branch,
        "commit"  => @build.commit.identifier,
        "command" => @build.project.command
      )
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
  end

  class ThreadedBuilder
    class << self
      attr_accessor :pool
    end

    def self.setup(size)
      self.pool = Bob::Engine::Threaded.new(size)
    end

    def self.build(build)
      self.pool.call(proc { Builder.new(build).build })
    end
  end
end
