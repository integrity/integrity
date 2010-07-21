require "resque"

module Integrity
  module ResqueBuilder
    def self.enqueue(build)
      Resque.enqueue BuildJob, build.id
    end

    module BuildJob
      @queue = :integrity

      def self.perform(build)
        Build.get!(build).run!
      end
    end
  end
end
