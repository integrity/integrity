require "resque"

module Integrity
  module ResqueBuilder
    def self.call(build)
      Resque.enqueue BuildJob, build.id
    end

    module BuildJob
      @queue = :integrity

      def self.perform(build)
        Builder.build Build.get(build)
      end
    end
  end
end
