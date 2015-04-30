module Pancakes
  module Background

    # Be sure to run this with separate dj process which has 1 worker and only runs off this queue
    class SerialStackJob
      def initialize(stack_id)
        @stack_id = stack_id
      end

      def queue_name
        'cluster_serial'
      end

      def max_attempts
        1
      end

      def stack
        @stack ||= Pancakes::Stack[@stack_id]
      end
    end

    class BringUpJob < SerialStackJob
      def perform
        stack.bring_down(freeze_dbs: false)
        stack.bring_up(thaw_dbs: false)
      end
    end

    class BringDownJob < SerialStackJob
      def perform
        stack.bring_down(freeze_dbs: false)
      end
    end

    class RestartWithSameCommitsJob < SerialStackJob
      def perform
        stack.restart_with_same_commits
      end
    end

    class RestartWithBranchHeadsJob < SerialStackJob
      def perform
        stack.restart_with_branch_heads
      end
    end

  end
end
