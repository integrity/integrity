module Integrity
  class StatsJob
    def perform
      send_honesty_stats
      Pancakes::Stack::CLUSTER_STATES.each do |state|
        send_pancakes_stats(state: state.to_s)
      end
      Delayed::Job.enqueue(self, run_at: (Time.now + 30.seconds))
    end

    def send_honesty_stats
      Integrity.logger.info 'sending honesty stats'

      Integrity.cluster.running_build_count_by_machine.each do |machine_ip,count|
        StatHatWrapper.post_value("honesty running builds #{machine_ip}", count)
      end

      StatHatWrapper.post_value("honesty running builds all", Integrity::Build.running.count)
      StatHatWrapper.post_value("honesty pending builds all", Integrity::Build.pending.count)
    end

    def send_pancakes_stats(state:)
      Integrity.logger.info "sending pancakes stats for state=#{state}"
      stacks = Pancakes::Stack.where(state: state)

      stack_count_by_ip(stacks).each do |ip,count|
        StatHatWrapper.post_value("pancakes #{state} stacks #{ip}", count)
      end

      StatHatWrapper.post_value("pancakes #{state} stacks total", stacks.count)
    end

    def stack_count_by_ip(stacks)
      stacks.map{|stack| stack.netmaster_unit.machine_ip }.reduce(Hash.new(0)){|memo,ip| memo[ip] += 1 ; memo }
    end

    def max_attempts
      1
    end

    def queue_name
      'stats'
    end
  end
end
