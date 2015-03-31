class StatsJob
  def perform(schedule_next: true)
    StatHatWrapper.post_value("honesty running builds all", Integrity::Build.running.count)
    StatHatWrapper.post_value("honesty pending builds all", Integrity::Build.pending.count)

    if schedule_next
      Delayed::Job.enqueue self, run_at: (Time.now + 30.seconds)
    end
  end

  def queue_name
    'stats'
  end
end
