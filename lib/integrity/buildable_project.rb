module Integrity
  class BuildableProject
    def self.call(buildable)
      return [] unless projects = Project.all(
        :uri.like => "#{buildable["uri"]}%",
        :branch   => buildable["branch"]
      )

      projects.inject([]) { |acc, p|
        acc.concat buildable["commits"].collect { |c| new(p, c["id"]) }
      }
    end

    def initialize(project, commit)
      @build = project.builds.create(:commit => {:identifier => commit})
    end

    def build
      @build.tap { |b| Integrity.builder.call(b) }
    end
  end
end
