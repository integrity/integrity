module Integrity
  class InstanceManager

    def utilization_metrics
      {
      pending: Build.pending.count,
      running: Build.running.count,
      machines: machines.count
      }
    end

    def machines
      refresh_machines unless @machines
      @machines
    end

    def refresh_machines
      @machines = Crust.get_machines
      reset_max_running_builds
    end

    def reset_max_running_builds
      Integrity.config.max_running_builds = capable_running_builds
    end

    def capable_running_builds
      machines.count * 3
    end
  end
end
