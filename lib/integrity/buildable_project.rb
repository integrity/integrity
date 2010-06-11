module Integrity
  class BuildableProject
    def self.call(buildable)
      projects = Project.all(:uri.like => "#{buildable["uri"]}%")

      projects =
        case
        when ! Integrity.auto_branch?
          projects.all(:branch => buildable["branch"])
        when project = projects.first(:branch => buildable["branch"])
          project
        when project = projects.first(:branch => "master")
          project.fork(buildable["branch"])
        end

      Array(projects).inject([]) { |acc, p|
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
