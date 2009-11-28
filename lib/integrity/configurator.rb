module Integrity
  class Configurator
    attr_accessor :directory, :builder, :logger, :base_uri, :user, :pass,
      :build_all

    def initialize
      yield self
    end

    def database=(uri)
      DataMapper.setup(:default, uri)
    end

    def directory=(dir)
      @directory = Pathname(dir)
    end

    def log=(log)
      @logger = Logger.new(log)
    end

    def base_uri=(uri)
      @base_uri = Addressable::URI.parse(uri)
    end

    def builder(*args)
      @builder ||= case args.first
        when :threaded
          Integrity::ThreadedBuilder.new(args.last)
        when :dj
          require "integrity/builder/delayed"
          Integrity::DelayedBuilder.new(args.last)
        else
          fail "Unknown builder #{name}"
        end
    end

    def push(*args)
      @push ||= begin
        fail "Unknown push service" unless args.first == :github
        [Bobette::GitHub, args.last]
      end
    end

    def protect?
      user && pass
    end

    alias_method :build_all?, :build_all
  end
end
