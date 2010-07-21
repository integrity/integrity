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
      # TODO auto_branch property
      return branches unless Integrity.config.auto_branch?
      Array(branch || forked)
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
