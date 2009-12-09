module Integrity
  class Configurator
    def initialize
      yield self
    end

    def database(uri)
      DataMapper.setup(:default, uri)
    end

    def database=(uri)
      warn "c.database = 'db uri' is deprecated; " \
       "use c.database 'db uri' instead"
      database(uri)
    end

    def directory(dir)
      Integrity.directory = Pathname(dir)
    end

    def directory=(dir)
      warn "c.directory = 'dir' is deprecated; " \
        "use c.directory 'dir' instead"
      directory(dir)
    end

    def base_url(url)
      Integrity.base_url = Addressable::URI.parse(url)
    end

    def base_url=(url)
      warn "c.base_url = 'http://example.org' is deprecated; " \
        "use c.base_url 'http://example.org' instead"
      base_url(url)
    end

    def base_uri=(url)
      warn "c.base_uri is deprecated; use c.base_url instead"
      base_url(url)
    end

    def log(log)
      Integrity.logger = Logger.new(log)
    end

    def log=(log)
      warn "c.log = 'file.log' is deprecated; " \
        "use c.log 'file.log' instead"
      log(log)
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

    def github_token(token)
      Integrity::App.set(:github_token, token)
    end

    def push(*args)
      warn "`c.push :github, 'TOKEN'` is deprecated; " \
       "use `c.github_token 'token'` instead"
      github_token(args.last)
    end

    def build_all!
      Integrity.app.enable(:build_all)
    end

    def build_all=(v)
      warn "c.build_all = true is deprecated; " \
        "use c.build_all! instead"
      build_all! if v
    end

    def user(v)
      Integrity.app.set(:user, v)
    end

    def user=(u)
      warn "c.user = 'you' is deprecated; " \
        "use c.user 'you' instead"
      user(u)
    end

    def pass(v)
      Integrity.app.set(:pass, v)
    end

    def pass=(p)
      warn "c.pass = 'secret' is deprecated; " \
        "use c.pass 'secret' instead"
      pass(p)
    end
  end
end
