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

      $0 = "watiress: #@name"
    end

    def to_s
      "Waitress(#@name)"
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
          puts "#{to_s} main_loop raised an error: #{e.class} '#{e.message}'"
          if retries_exhausted?
            puts "#{to_s} retries exhausted"
            raise(e)
          else
            puts "#{to_s} retrying"
            sleep 1
            inc_retries
          end
        end
      end
    end

    def run_async(&block)
      @thread = Thread.new do
        puts "started thread for #{to_s}"
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
      super('node_count_waitress', 5)
    end

    def work
      curr_node_count = HonestyCluster::SwarmBackend.node_count
      if self.last_node_count != curr_node_count
        puts "node_count changed from #{self.last_node_count || 'nil'} to #{curr_node_count}"
        Integrity::Event.trigger('machine_count_changed')
      #else
        #puts "node_count still at #{self.last_node_count || 'nil'}"
      end
      self.last_node_count = curr_node_count
    end
  end
end
