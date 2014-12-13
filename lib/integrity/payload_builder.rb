module Integrity
  class PayloadBuilder

    def self.build(payload, build_all)
      new(payload, build_all).build
    end

    def initialize(payload, build_all)
      @payload   = payload
      @build_all = build_all
    end

    def build
      builds.first
    end

    def project
      projects.first
    end

    def builds
      @builds ||=
        projects.inject([]) do |list, project|
          list.concat commits.map{|c| project.build(c) }
        end
    end

    def projects
      @projects ||= ProjectFinder.find(@payload.repo)
    end

    def commits
      @commits ||= @build_all ? @payload.commits : [@payload.head]
    end

  end
end
