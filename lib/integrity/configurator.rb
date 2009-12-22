module Integrity
  class Configurator
    def initialize
      yield self
    end

    def database(uri)
      DataMapper.setup(:default, uri)
    end

    def directory(dir)
      Integrity.directory = Pathname(dir)
    end

    def base_url(url)
      Integrity.base_url = Addressable::URI.parse(url)
    end

    def log(log)
      Integrity.logger = Logger.new(log)
    end

    def builder(name, args=nil)
      Integrity.builder =
        case name
        when :threaded
          Integrity::ThreadedBuilder.new(args || 2, Integrity.logger)
        when :dj
          require "integrity/builder/delayed"
          Integrity::DelayedBuilder.new(args)
        when :resque
          require "integrity/builder/resque"
          Integrity::ResqueBuilder
        else
          raise ArgumentError, "Unknown builder #{name}"
        end
    end

    def push(token)
      Integrity::App.set(:push, token)
    end

    def github(token)
      Integrity::App.set(:github, token)
    end

    def build_all!
      Integrity.app.enable(:build_all)
    end

    def user(v)
      Integrity.app.set(:user, v)
    end

    def pass(v)
      Integrity.app.set(:pass, v)
    end
  end
end
