module HonestyCluster

  class WaitressError < RuntimeError ; end

  class Waitress

    class << self
      @@_waitresses = []

      def all
        @@_waitresses
      end

      def register(waitress)
        @@_waitresses << waitress
      end
    end

    attr_reader :name, :sleep_interval, :retries, :thread

    def initialize(name, sleep_interval=1)
      @name = name
      @sleep_interval = sleep_interval
      @max_retries = 5
      @retries = 0
      @thread = nil
      self.class.register(self)
    end

    def work
      nil
    end

    def retries_exhausted?
      @retries >= @max_retries
    end

    def run(&block)
      raise(WaitressError, "wont run. retries are exhausted.") if retries_exhausted?

      loop do
        begin
          if block
            block.call
          else
            work
          end
          sleep(sleep_interval)
        rescue StandardError => e
          puts "Waitress(#@name) main_loop raised an error: #{e.class} '#{e.message}'"
          if retries_exhausted?
            puts "Waitress(#@name) retries exhausted"
            raise(e)
          else
            puts "Waitress(#@name) retrying"
            sleep 1
            inc_retries
          end
        end
      end
    end

    def run_async(&block)
      @thread = Thread.new do
        run(&block)
      end
    end

    private def inc_retries
      @retries += 1
    end
  end

  class NodeCountWaitress < Waitress
    attr_accessor :last_node_count

    def initialize
      super('node_count_waitress')
    end

    def work
      curr_node_count = HonestyCluster::SwarmBackend.node_count
      if last_node_count != curr_node_count
        Integrity::Event.trigger('machine:added')
      end
      last_node_count = curr_node_count
    end
  end
end
