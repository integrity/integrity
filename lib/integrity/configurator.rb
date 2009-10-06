module Integrity
  class Configurator
    attr_accessor :builder, :logger, :base_uri,
      :user, :pass, :hash_pass, :build_all

    def initialize
      yield(self)
    end

    def database=(uri)
      DataMapper.setup(:default, uri)
    end

    def directory=(dir)
      Bob.directory = dir
    end

    def directory
      Bob.directory
    end

    def builder=(builder)
      @builder = builder
    end

    def log=(log)
      @logger = Logger.new(log)
      Bob.logger = @logger
    end

    def protect?
      user && pass
    end

    def hash_pass?
      !! hash_pass
    end

    def build_all?
      !! build_all
    end
  end
end
