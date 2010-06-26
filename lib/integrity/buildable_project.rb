module Integrity
  class BuildableProject
    class Finder
      def self.find(uri, branch)
        new(uri, branch).find
      end

      def initialize(uri, branch)
        @uri    = uri
        @branch = branch
      end

      def find
        return branches unless auto_branch?
        Array(branch || forked)
      end

      def auto_branch?
        !! Integrity.auto_branch
      end

      def branches
        all.all(:branch => @branch)
      end

      def branch
        all.first(:branch => @branch)
      end

      def forked
        if master = all.first("master")
          master.fork(@branch)
        end
      end

      def all
        @all ||= Project.all(:uri.like => "#{@uri}%")
      end
    end

    def self.call(buildable)
      projects = Finder.find(buildable["uri"], buildable["branch"])
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
