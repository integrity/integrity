module Integrity
  class PayloadBuilder

    def self.build(payload)
      new(payload).build
    end

    def initialize(payload)
      @payload = payload
    end

    def build
      @build ||= project.build(commit)
    end

    def project
      @project ||= ProjectFinder.find(@payload.repo)
    end

    def commit
      @commit ||= @payload.commit
    end

  end
end
