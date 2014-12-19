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
      Project.first(:uri.like => "#{@repo.uri}%")
    end
  end
end
