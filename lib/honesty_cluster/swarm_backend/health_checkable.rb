module HonestyCluster
  module SwarmBackend

    class HealthCheck
      attr_reader :status, :message

      def initialize(status, message=nil)
        @status = status
        @message = message
      end

      def healthy?
        status == :complete
      end
    end

    module HealthCheckable
      extend ActiveSupport::Concern

      #included do
      #end

      def create_event_for_health_check(health_check)
        status = health_check.status
        msg    = health_check.msg
        raise("invalid create_health_check_event status '#{status}'") unless HonestyEvent::STATUS_ENDINGS.include?(status.to_sym)
        status_prefix = status == :in_progress ? 'CREATE' : 'HEALTH_CHECK'
        add_event(source: 'honesty', type: self.class._health_check_type, status: "#{status_prefix}_#{status.upcase}", status_message: msg)
        return health_check.healthy?
      end

      def initial_health_check
        create_health_check_event(:in_progress)
      end

      def last_health_check
        events_dataset.where(type: self.class._health_check_type).reverse_order(:created_at).limit(1).first
      end

      def check_health!
        create_event_for_health_check(current_health)
      end

      # must return an instance of HealthCheck
      def current_health
        raise("must implement")
      end

      module ClassMethods
        attr_reader :_health_check_type

        def health_check_type(type)
          raise("invalid health_check_type '#{type}'") unless type && !type.empty?
          @_health_check_type = "#{type}::HealthCheck"
        end
      end
    end
  end
end
