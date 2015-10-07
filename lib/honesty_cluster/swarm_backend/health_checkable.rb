module HonestyCluster
  module SwarmBackend

    # check for the status of one particular thing
    class StatusCheck
      attr_reader :status, :message

      # all possible statuses ordered by importance
      # ie, if a status is failed, then we dont care about statuses after failed in this list
      PRIORITIZED_STATUSES = [
        :failed,
        :in_progress,
        :complete,
      ]

      def initialize(status, message=nil)
        raise("invalid status '#{status}'") unless PRIORITIZED_STATUSES.include?(status)
        @status = status
        @message = message
      end

      def okay?
        status == :complete
      end
    end

    # represent the overall health of some resource by aggregating it's StatusChecks
    class HealthCheck
      attr_reader :status_checks

      def initialize(status_checks)
        @status_checks = status_checks
      end

      def status
        prioritized_status_checks[:status]
      end

      def message
        prioritized_status_checks[:checks].map(&:message).join('; ')
      end

      def healthy?
        #status_checks.map(&:"okay?")reduce(true){|memo,val| memo && val }
        status == :complete
      end

      private def grouped_status_checks
        @__groups ||= status_checks.group_by do |check|
          check.status
        end
      end


      # return the status checks with the most important status
      private def prioritized_status_checks
        StatusCheck::PRIORITIZED_STATUSES.map do |status|
          [
            status,
            grouped_status_checks[status] || [],
          ]
        end
        .each do |status,group|
          if !group.empty?
            return { status: status, checks: group }
          end
        end
        raise('expected some status checks to prioritize')
      end
    end

    module HealthCheckable
      extend ActiveSupport::Concern

      #included do
      #end

      def create_event_for_health_check(health_check)
        status = health_check.status
        msg    = health_check.message
        status_prefix = status == :in_progress ? 'CREATE' : 'HEALTH_CHECK'
        add_event(source: 'honesty', type: self.class._health_check_type, status: "#{status_prefix}_#{status.upcase}", status_message: msg)
        return health_check.healthy?
      end

      def initial_health_check
        create_event_for_health_check(HealthCheck.new([StatusCheck.new(:in_progress, 'created')]))
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
