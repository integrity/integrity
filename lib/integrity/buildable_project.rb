module Integrity
  class BuildableProject
    def self.call(buildable)
      projects = ProjectFinder.find(buildable["uri"], buildable["branch"])
      projects.inject([]) { |acc, project|
        acc.concat buildable["commits"].collect{|commit| new(project, commit)}
      }
    end

    def initialize(project, commit)
      @build = project.builds.create(:commit => {
        :identifier   => commit["id"],
        :author       => commit_author(commit),
        :message      => commit["message"],
        :committed_at => commit["timestamp"]
      })
    end

    def commit_author(commit)
      unless author = commit["author"]
        return Author::AuthorStruct.new("unknown", nil)
      end

      Author::AuthorStruct.new(
        author["name"] || "unknown",
        author["email"]
      )
    end

    def build
      @build.tap { |b| Integrity.builder.call(b) }
    end
  end
end
