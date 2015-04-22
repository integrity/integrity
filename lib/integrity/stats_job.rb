module Integrity
  class StatsJob
    def perform
      Integrity.logger.info 'sending stats'

      FleetHelper.running_build_count_by_machine.each do |machine_ip,count|
        StatHatWrapper.post_value("honesty running builds #{machine_ip}", count)
      end

      StatHatWrapper.post_value("honesty running builds all", Integrity::Build.running.count)
      StatHatWrapper.post_value("honesty pending builds all", Integrity::Build.pending.count)

      Delayed::Job.enqueue(self, run_at: (Time.now + 30.seconds))
    end

    def max_attempts
      1
    end

    def queue_name
      'stats'
    end
  end
end
