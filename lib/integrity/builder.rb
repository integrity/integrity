module Integrity
  class BuildableProject
    def self.call(buildable)
      return [] unless project = Project.first(:scm => buildable["scm"],
        :uri => buildable["uri"],
        :branch => buildable["branch"]
      )
      buildable["commits"].collect { |id| new(project, id) }
    end

    def initialize(project, commit)
      @project = project
      @commit  = commit
    end

    def build
      b = @project.builds.create(:commit => Commit.new(:identifier => @commit))
      Integrity.config.builder.build(b)
      b
    end
  end

  class Builder < Bob::Builder
    def initialize(b)
      @buildable = {
        "scm"     => b.project.scm,
        "uri"     => b.project.uri.to_s,
        "branch"  => b.project.branch,
        "commit"  => b.commit.identifier,
        "command" => b.project.command
      }
      @build = b
    end

    def started(metadata)
      @build.update(:started_at => Time.now)
      @build.commit.update(metadata)
    end

    def completed(status, output)
      @build.completed_at = Time.now
      @build.successful   = status
      @build.output       = output
      @build.save
      @build.project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end
  end

  class ThreadedBuilder
    class << self
      attr_accessor :pool
    end

    def self.setup(opts={})
      self.pool = Bob::Engine::Threaded.new(opts[:size] || 2)
    end

    def self.build(build)
      self.pool.call(proc { Builder.new(build).build })
    end
  end
end
