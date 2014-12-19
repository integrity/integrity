module Integrity
  class ProjectFinder

    def self.find(repo)
      new(repo).project
    end

    def initialize(repo)
      @repo = repo
    end

    def project
      project = find_by_uri
      project.get_branch(@repo.branch)
      project
    end

    private

    def find_by_uri
      project = Project.first(:uri.like => "#{@repo.uri}%")
      raise DataMapper::NotFound, 'Project URI does not exist' unless project
      project
    end
  end
end
