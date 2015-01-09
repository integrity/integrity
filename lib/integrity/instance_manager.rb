module Integrity
  class InstanceManager

    LARGE_BUILDS_PER_MACHINE = 2
    SMALL_BUILDS_PER_MACHINE = LARGE_BUILDS_PER_MACHINE * 8

    def utilization_metrics
      refresh_machines
      {
      pending_builds: Build.pending.count,
      running_builds: Build.running.count,
      machines: machines.count,
      new_machines_requested: new_machines_required
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
      machines.count * LARGE_BUILDS_PER_MACHINE
    end

    def new_machines_required
      (load_deficit.to_f / SMALL_BUILDS_PER_MACHINE).ceil
    end

    def load_deficit
      load_need - load_capacity
    end

    def load_capacity
      (machines.count * SMALL_BUILDS_PER_MACHINE)
    end

    def load_need
      pending_load_need + running_load_need
    end

    def pending_load_need
      Build.pending.map{|b| b.load_score}.sum
    end

    def running_load_need
      Build.running.map{|b| b.load_score}.sum
    end

  end
end
