module Integrity
  class ProjectFinder
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
end
