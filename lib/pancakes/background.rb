module Pancakes
  module Background

    # Be sure to run this with separate dj process which has 1 worker and only runs off this queue
    class SerialClusterJob
      def queue_name
        'cluster_serial'
      end

      def max_attempts
        1
      end

      def destroy_failed_jobs?
        false
      end

      def assert_stack!(stack)
        raise "stack with id=#{id} not found" unless stack
      end
    end

    class BringUpJob < SerialClusterJob
      def perform(id)
        stack = Pancakes::Stack.find(id)
        assert_stack!(stack)
        stack.bring_down(force: true)
        stack.bring_up
      end
    end

    class BringDownJob < SerialClusterJob
      def perform(id)
        stack = Pancakes::Stack.find(id)
        assert_stack!(stack)
        stack.bring_down(force: true)
      end
    end

    class RestartsJob < SerialClusterJob
      def perform(id, restart_method)
        stack = Pancakes::Stack.find(id)
        assert_stack!(stack)
        restart_method = restart_method.to_sym

        if stack.respond_to?(restart_method) && restart_method.to_s.start_with?('restart')
          stack.send(restart_method)
        else
          raise "can't call #{restart_method} from #{self.class}"
        end
      end
    end

  end
end
