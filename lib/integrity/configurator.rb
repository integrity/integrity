module Integrity
  class Configurator
    attr_accessor :directory, :builder, :logger, :base_uri, :user, :pass,
      :build_all

    def initialize
      yield(self)
    end

    def database=(uri)
      DataMapper.setup(:default, uri)
    end

    def directory=(dir)
      @directory = Pathname(dir)
    end

    def base_uri=(uri)
      @base_uri = Addressable::URI.parse(uri)
    end

    def builder(*args)
      @builder ||= begin
        klass = builder_class(args.first)
        case args.size
        when 1 then klass
        when 2 then klass.tap { |b| b.setup(args.last) }
        else
          raise ArgumentError
        end
      end
    end

    def push(*args)
      @push ||= [push_class(args.first), args.last]
    end

    def log=(log)
      @logger = Logger.new(log)
    end

    def protect?
      user && pass
    end

    def build_all?
      !! build_all
    end

    private
      def builder_class(name)
        case name
        when :threaded then Integrity::ThreadedBuilder
        when :dj
          require "integrity/delayed_builder"
          Integrity::DelayedBuilder
        else
          fail "Unknown builder #{name}"
        end
      end

      def push_class(name)
        case name
        when :github then Bobette::GitHub
        else
          fail "Unknown push service #{name}"
        end
      end
  end
end
