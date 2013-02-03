module Integrity
  # A builder that builds when explicitly told to.
  #
  # It is used in the test suite to avoid races between threads.
  class ExplicitBuilder
    def initialize
      @builds = []
    end
    
    def enqueue(build)
      @builds << build
    end
    
    def wait!
      until @builds.empty?
        @builds.shift.run!
      end
    end
  end
end
