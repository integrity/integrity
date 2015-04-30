module Pancakes
  module Background

    # Be sure to run this with separate dj process which has 1 worker and only runs off this queue
    class SerialStackJob
      def initialize(stack_id, opts={})
        @stack_id = stack_id
        @opts     = opts
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

      def error(job, exception)
        Pancakes.logger.error "job failed with #{exception.to_s}"
        Pancakes.logger.error "backtrace:\n\n#{exception.backtrace.map{|l| ' '*4 + l }.join("\n")}\n"
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

        if @opts[:destroy] == true
          stack.destroy
        end
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
