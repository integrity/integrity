module Integrity
  class Configuration
    attr_reader :directory,
      :base_url,
      :builder

    attr_accessor :build_all,
      :auto_branch,
      :github_token,
      :log,
      :username,
      :password

    def build_all?
      !! @build_all
    end

    def auto_branch?
      !! @auto_branch
    end

    def github_enabled?
      !! @github_token
    end

    def protected?
      @username && @password
    end

    def logger
      @logger ||= Logger.new(@log)
    end

    def database=(uri)
      DataMapper.setup(:default, uri)
    end

    def directory=(dir)
      @directory = Pathname(dir)
    end

    def base_url=(url)
      @base_url = Addressable::URI.parse(url)
    end

    def builder=(builder)
      name, args = builder

      @builder =
        case name
        when :threaded
          require "integrity/threaded_builder"
          Integrity::ThreadedBuilder.new(args || 2, logger)
        when :dj
          require "integrity/delayed_builder"
          Integrity::DelayedBuilder.new(args)
        when :resque
          require "integrity/resque_builder"
          Integrity::ResqueBuilder
        else
          raise ArgumentError, "Unknown builder #{name}"
        end
    end
  end
end
