module Integrity
  class InstanceManager

    LARGE_BUILDS_PER_MACHINE = 3
    SMALL_BUILDS_PER_MACHINE = LARGE_BUILDS_PER_MACHINE * 8

    def utilization_metrics
      refresh_machines
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
      machines.count * LARGE_BUILDS_PER_MACHINE
    end

    def new_machines_required
      load_deficit / SMALL_BUILDS_PER_MACHINE
    end

    def load_deficit
      load_need - load_capacity
    end

    def load_capacity
      (machines.count * SMALL_BUILDS_PER_MACHINE)
    end

    def load_need
      pending_load_score + running_load_score
    end

    private

    def pending_load_score
      Build.pending.map{|b| b.load_score}.sum
    end

    def running_load_score
      Build.running.map{|b| b.load_score}.sum
    end

  end
end
