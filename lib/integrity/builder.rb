module Integrity
  class Project
    def self.for(buildable)
      first(
        :scm    => buildable["scm"],
        :uri    => buildable["uri"],
        :branch => buildable["branch"]
      )
    end
  end

  class BuildableProject
    def self.call(payload)
      return [] unless project = Project.for(payload)
      payload["commits"].map { |c| new(project, c["id"]) }
    end

    def initialize(project, commit)
      @buildable = project.attributes.inject({}) { |h, (k,v)|
        h.update(k.to_s => v)
      }.merge("commit" => commit)
    end

    def build
      Integrity.config.builder.new(@buildable).build
    end
  end

  class ProjectBuilder < Bob::Builder
    def started(metadata)
      @project = Project.for(@buildable)
      @build = @project.builds.create(
        :started_at => Time.now, :commit => Commit.new(metadata))
    end

    def completed(status, output)
      @build.completed_at = Time.now
      @build.successful   = status
      @build.output       = output
      @build.save
      @project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end
  end

  class ThreadedBuilder
    class << self
      attr_accessor :pool
    end

    def self.setup(opts={})
      self.pool = Bob::Engine::Threaded.new(opts[:size] || 2)
    end

    def initialize(buildable)
      @buildable = buildable
    end

    def build
      self.class.pool.call(proc { ProjectBuilder.new(@buildable).build })
    end
  end
end
