module Integrity
  class Configuration
    attr_reader :directory, :base_url, :logger, :builder, :github_token,
      :build_all, :auto_branch, :username, :password

    def database=(uri)
      DataMapper.setup(:default, uri)
    end

    def directory=(dir)
      @directory = Pathname(dir)
    end

    def base_url=(url)
      @base_url = Addressable::URI.parse(url)
    end

    # TODO
    def log=(log)
      @log = log
    end

    def logger
      @logger ||= Logger.new(@log)
    end

    def builder=(builder)
      name, args = builder

      @builder =
        case name
        when :threaded
          Integrity::ThreadedBuilder.new(args || 2, logger)
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

    def github_token=(token)
      @github_token = token
    end

    def github_enabled?
      !! @github_token
    end

    def build_all=(v)
      @build_all = v
    end

    def build_all?
      !! @build_all
    end

    def auto_branch=(v)
      @auto_branch =v
    end

    def auto_branch?
      !! @auto_branch
    end

    def username=(v)
      @username = v
    end

    def password=(v)
      @password = v
    end

    def protected?
      @username && @password
    end
  end
end
