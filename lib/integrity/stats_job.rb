class StatsJob

  WORKERS = {
    '10.0.80.2' => 'front-panel-2',
    '10.0.80.6' => 'front-panel-6',
    '10.0.80.10' => 'worker-10-dtest',
    '10.0.80.11' => 'worker-11-dtest',
  }

  def perform(schedule_next: true)
    Integrity.logger.info 'sending stats'
    FleetHelper.running_build_count_by_machine.each do |machine_ip,count|
      StatHatWrapper.post_value("honesty running builds #{self.class.pretty_worker_name(machine_ip)}", count)
    end

    StatHatWrapper.post_value("honesty running builds all", Integrity::Build.running.count)
    StatHatWrapper.post_value("honesty pending builds all", Integrity::Build.pending.count)

    if schedule_next
      Delayed::Job.enqueue self, run_at: (Time.now + 30.seconds)
    end
  end

  def queue_name
    'stats'
  end

  def self.pretty_worker_name(ip)
    WORKERS[ip] || ip
  end
end
