module Integrity
  class BuildableProject
    def self.call(buildable)
      projects = ProjectFinder.find(buildable["uri"], buildable["branch"])
      projects.inject([]) { |acc, project|
        acc.concat buildable["commits"].collect { |commit|
          if author = commit.delete("author")
            commit["author"] = "#{author["name"]} <#{author["email"]}>"
          end

          new(project, commit)
        }
      }
    end

    def initialize(project, commit)
      @build = project.builds.create(:commit => {
        :identifier   => commit["id"],
        :author       => commit["author"],
        :message      => commit["message"],
        :committed_at => commit["timestamp"]
      })
    end

    def build
      @build.tap { |b| Integrity.builder.call(b) }
    end
  end
end
