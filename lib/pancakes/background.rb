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
        ff = File.open('/tmp/pk-test.log', 'a')
        ff.puts "stack[%s] bring_up starting" % [stack.name]
        ff.flush
        stack.bring_down(freeze_dbs: false)
        stack.bring_up(thaw_dbs: false)
        ff.puts "stack[%s] bring_up done with state=%s" % [stack.name, stack.state]
        ff.close
      end
    end

    class BringDownJob < SerialStackJob
      def perform
        stack.update_all(desired_state: :off)
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
