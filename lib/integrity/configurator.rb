module Integrity
  class Configurator
    attr_accessor :user, :pass, :build_all

    def initialize
      yield self
    end

    def database=(uri)
      DataMapper.setup(:default, uri)
    end

    def directory=(dir)
      Integrity.directory = Pathname(dir)
    end

    def base_url=(url)
      warn "c.base_uri is deprecated; use c.base_url instead"
      Integrity.base_url = Addressable::URI.parse(url)
    end

    def base_uri=(url)
      self.base_url = url
    end

    def log=(log)
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
        else
          raise ArgumentError, "Unknown builder #{name}"
        end
    end

    def github_token=(token)
      Integrity::App.set(:github_token, token)
    end

    def push(*args)
      warn "`c.push :github, 'TOKEN'` is deprecated; " \
       "use `c.github_token = 'token'` instead"
      self.github_token = args.last
    end

    def protect?
      user && pass
    end

    alias_method :build_all?, :build_all
  end
end
