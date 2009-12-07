require "thread"

module Integrity
  # A thread pool based build engine. This engine simply adds jobs to an
  # in-memory queue, and processes them as soon as possible.
  class ThreadedBuilder
    # The optional pool size controls how many threads will be created.
    def initialize(pool_size, logger)
      @pool = ThreadPool.new(pool_size, logger)
    end

    # Adds a job to the queue.
    def call(build)
      @pool << proc { Builder.build(build) }
    end

    # The number of jobs currently in the queue.
    def njobs
      @pool.njobs
    end

    # This method will not return until #njobs returns 0.
    def wait!
      Thread.pass until @pool.njobs == 0
    end

    # Manage a pool of threads, allowing for spin up / spin down of the
    # contained threads.
    # Simply processes work added to it's queue via #push.
    # The default size for the pool is 2 threads.
    class ThreadPool
      # A thread safe single value for use as a counter.
      class Incrementor
        # The value passed in will be the initial value.
        def initialize(v = 0)
          @m = Mutex.new
          @v = v
        end

        # Add the given value to self, default 1.
        def inc(v = 1)
          sync { @v += v }
        end

        # Subtract the given value to self, default 1.
        def dec(v = 1)
          sync { @v -= v }
        end

        # Simply shows the value inspect for convenience.
        def inspect
          @v.inspect
        end

        # Extract the value.
        def to_i
          @v
        end

        private

        # Wrap the given block in a mutex.
        def sync(&b)
          @m.synchronize &b
        end
      end

      # The number of threads in the pool.
      attr_reader :size

      # The job queue.
      attr_reader :jobs

      # Set the size of the thread pool. Asynchronously run down threads
      # that are no longer required, and synchronously spawn new required
      # threads.
      def size=(other)
        @size = other

        if @workers.size > @size
          (@workers.size - @size).times { @workers.shift[:run] = false }
        else
          (@size - @workers.size).times { @workers << spawn }
        end
      end

      # Default pool size is 2 threads.
      def initialize(size, logger)
        @jobs    = Queue.new
        @njobs   = Incrementor.new
        @workers = Array.new(size) { spawn }
        @logger  = logger
      end

      # Adds a job to the queue, the job can be any number of objects
      # responding to call, and/or a block.
      def add(*jobs, &blk)
        jobs = jobs + Array(blk)

        jobs.each { |job|
          @jobs << job
          @njobs.inc
        }
      end

      alias_method :push, :add
      alias_method :<<,   :add

      # A peak at the number of jobs in the queue. N.B. May differ, but
      # should be more accurate than +jobs.size+.
      def njobs
        @njobs.to_i
      end

      private

      # Create a new thread and return it. The thread will run until the
      # thread-local value +:run+ is changed to false or nil.
      def spawn
        Thread.new {
          c = Thread.current
          c[:run] = true

          while c[:run]
            job = @jobs.pop
            begin
              job.call
            rescue Exception => e
              @logger.error("Exception occured during build: #{e.message}")
            end
            @njobs.dec
          end
        }
      end
    end
  end
end
