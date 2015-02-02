module Integrity
  class InstanceManager

    LARGE_BUILDS_PER_MACHINE = 2
    SMALL_BUILDS_PER_MACHINE = LARGE_BUILDS_PER_MACHINE * 8

    attr_accessor :machines, :load_utilization

    def initialize
    end

    def utilization_metrics
      load_utilization.first.metrics
    end

    def refresh
      @machines = Crust.get_machines
      reset_max_running_builds
      @load_utilization = LoadUtilization.log(
        @machines,
        pending_load_need,
        running_load_need,
        load_need,
        load_capacity,
        load_deficit,
        new_machines_required,
        capable_running_builds
      )
    end

    def reset_max_running_builds
      old_max = Integrity.max_running_builds
      new_max = capable_running_builds
      Integrity.config.max_running_builds = new_max
      if old_max <  new_max
        Integrity::Event.trigger('machine:added')
      end
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
