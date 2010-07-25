module Integrity
  class ProjectFinder
    def self.find(repo)
      new(repo).find
    end

    def initialize(repo)
      @repo = repo
    end

    def find
      unless Integrity.config.auto_branch?
        return branches
      end

      Array(branch || forked)
    end

    def branches
      all.all(:branch => @repo.branch)
    end

    def branch
      all.first(:branch => @repo.branch)
    end

    def forked
      if master = all.first("master")
        master.fork(@repo.branch)
      end
    end

    def all
      @all ||= Project.all(:uri.like => "#{@repo.uri}%")
    end
  end
end
