require "resque"
require "resque/server"

module Integrity
  class ResqueServer < Resque::Server
    include Sinatra::Authorization

    def authorization_realm
      'Integrity'
    end

    def authorize(user, password)
      unless Integrity.config.protected?
        return true
      end

      Integrity.config.username == user &&
        Integrity.config.password == password
    end

    before do
      login_required
    end
  end

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
      ['resque', ResqueServer]
    end
  end
end
