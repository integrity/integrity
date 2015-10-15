module Pancakes
  module Fleet

    attr_reader :machine_id, :expires_at

    class Metrics
      def initialize(machine_id, expires_at, metrics)
        @machine_id = machine_id
        @expires_at = expires_at
        @metrics = metrics
      end

      def to_h
        @metrics
      end

      %w[load1 load5 load15 memtotal memfree memavailable diskfree ncpus].each do |method|
        define_method(method) do
          @metrics[method]
        end
      end
    end

    class Etcd
      include ClassLogger

      DEFAULT_WATCH_TIMEOUT = 30
      STATES_KEY = '/_coreos.com/fleet/state'
      URL_SCHEME = 'etcd://'
      METRICS_KEY = '/grnds/metrics'

      attr_reader :client

      def initialize
        @client = ::Etcd.client(host: URI.parse(ENV['FLEETCTL_ENDPOINT']).host, port: 4001)
      end

      def get_all_metrics
        resp = @client.get(METRICS_KEY, recursive: true)
        resp.node.children.map do |metrics_node|
          machine_id = metrics_node.key.split('/').last
          Metrics.new(machine_id, metrics_node.expiration, JSON.parse(metrics_node.value))
        end
      rescue ::Etcd::KeyNotFound
        nil
      end

      # this seems useful
      #def watch_states
        #loop do
          #resp = @client.watch(STATES_KEY, recursive: true, timeout: 60)
          #puts resp.key
        #end
      #end

      def get(key)
        key = key.sub(URL_SCHEME, '') if key.start_with?(URL_SCHEME)
        @client.get(key).value
      rescue ::Etcd::KeyNotFound
        nil
      end

      def watch_unit_for_active_state(service_fname, state, timeout:)
        Pancakes.loop_with_timeout(timeout: timeout) do |remaining|
          resp = watch_unit(service_fname)
          if resp
            as = active_state(resp)
            logger.debug "watched #{state_key(service_fname)} and got activeState=#{as}"
            if as == state
              return state
            end
          end
        end
      rescue Pancakes::TimeoutError => e
        logger.warn e.message
        raise
      end

      # @api private
      def watch_unit(service_fname)
        tries ||= 5
        mi = get_unit_state_modified_index(service_fname) + 1 # add 1 to wait for the next change
        logger.debug "watching #{state_key(service_fname)} after index modifiedIndex=#{mi}"
        resp = @client.watch(state_key(service_fname), index: mi, timeout: DEFAULT_WATCH_TIMEOUT)
        resp
      rescue ::Etcd::KeyNotFound
        if (tries -= 1) > 0
          sleep 0.5
          retry
        else
          logger.info "could not find key #{state_key(service_fname)}"
          return nil
        end
      rescue Net::ReadTimeout
        logger.info "timeout watching key #{state_key(service_fname)}"
        return nil
      end

      # @api private
      def active_state(resp)
        JSON.parse(resp.value)['activeState']
      end

      # @api private
      def get_unit_state_modified_index(service_fname)
        mi = @client.get(state_key(service_fname)).node.modified_index
        logger.debug "got modifiedIndex=#{mi} for #{state_key(service_fname)}"
        mi
      end

      # @api private
      def get_unit_state(service_fname)
        @client.get(state_key(service_fname))
      end

      # @api private
      def state_key(service_fname)
        format('%s/%s', STATES_KEY, service_fname)
      end
    end
  end
end
