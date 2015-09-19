module Integrity
  class Build
    module Status

      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      HUMAN_STATUS = {
        success:  "Built %s successfully",
        failed:   "Built %s and failed",
        pending:  "%s hasn't been built yet",
        building: "%s is building",
        killed: "%s was killed",
        cancelled: "%s was cancelled"
      }

      module ClassMethods
        def pending(query = :all)
          scope(query, started_at: nil, completed_at: nil, state: nil, order: :created_at.asc)
        end

        def running(query = :all)
          scope(query, :started_at.not => nil, completed_at: nil, state: nil, order: :started_at.asc)
        end

        def orphaned(query = :all)
          max = Integrity.max_run_time
          scope(query, :started_at.lt => max.minutes.ago, completed_at: nil, order: :started_at.asc)
        end

        def completed(query = :all)
          scope(query, :completed_at.not => nil, order: :started_at.asc)
        end

        def update_fleetctl_status
          statuses = Integrity.cluster.get_service_status
          statuses.each do |id, status|
            get(id).try(:update_fleetctl_status, status)
          end
        end
      end

      def status
        return state.to_sym if state
        case
          when building?   then :building
          when pending?    then :pending
          when successful? then :success
          when failed?     then :failed
          else :unknown
        end
      end

      def human_status
        HUMAN_STATUS[status].try(:%, sha1_short)
      end

      def in_progress?
        pending? || building?
      end

      def idle?
        pending? || completed? || interrupted?
      end
      alias_method :not_running?, :idle?

      def interrupted?
        killed? || cancelled?
      end

      def completed?
        !completed_at.nil?
      end

      def finished?
        completed? && !interrupted?
      end

      def started?
        !started_at.nil?
      end

      def successful?
        successful == true
      end

      def failed?
        !successful?
      end

      def building?
        started?  && !completed? && !interrupted?
      end
      alias_method :running?, :building?

      def pending?
        started_at.nil? && completed_at.nil?
      end

      def killed?
        state && state.to_sym == :killed
      end

      def cancelled?
        state && state.to_sym == :cancelled
      end

      def orphanned?
        started_at < 1.hour.ago && completed_at.nil?
      end

      def bootstrap_class
        case status
          when :building then 'info'
          when :success then 'success'
          when :failed then 'danger'
          when :pending then 'warning'
          when :killed then 'killed'
        end
      end

      def update_fleetctl_status(status)
        #if app_status = status.detect{|s| s[:type] == 'app' }
          #update(fleetctl_status: app_status[:active_state], machine_ip: app_status[:machine_ip])
        #end
        #If the build service file fails, we change its status to 'killed' from 'building'
        consider_mercy_kill
      end
    end
  end
end
