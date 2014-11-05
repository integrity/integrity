require "resque"
require "resque/server"

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

    def self.web_ui
      ['resque', Resque::Server]
    end
  end
end
