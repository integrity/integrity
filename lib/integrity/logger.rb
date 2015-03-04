module Integrity
  class Logger < DataMapper::Logger

    def initialize(level)
      super(STDOUT, level)
    end
  
  end
end
