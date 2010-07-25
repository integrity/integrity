module Integrity
  class BuildablePayload
    def self.build(payload, head)
      new(payload, head).build
    end

    def initialize(payload, head)
      @payload = payload
      @head    = head
    end

    def build
      builds.each { |build| build.run }.size
    end

    def builds
      @builds ||=
        projects.inject([]) { |acc, project|
          acc.concat commits.map { |c| project.builds.create(:commit => c) }
        }
    end

    def commits
      @commits ||= @head ? [@payload.head] : @payload.commits
    end

    def projects
      @projects ||= ProjectFinder.find(@payload.repo)
    end
  end
end
