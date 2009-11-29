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
      @build = project.builds.create(:commit => {:identifier => commit})
    end

    def build
      @build.tap { |b| Integrity.config.builder.call(b) }
    end
  end
end
