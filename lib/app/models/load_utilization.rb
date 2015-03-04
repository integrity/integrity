module Integrity
  class LoadUtilization
    include DataMapper::Resource

    property :id,                 Serial
    property :pending_builds,     Integer, default: 0,  required: true
    property :running_builds,     Integer, default: 0,  required: true
    property :active_machines,    Integer, default: 0,  required: true
    property :pending_load,       Integer, default: 0,  required: true
    property :running_load,       Integer, default: 0,  required: true
    property :load_requirement,   Integer, default: 0,  required: true
    property :load_capacity,      Integer, default: 0,  required: true
    property :load_deficit,       Integer, default: 0,  required: true
    property :machines_required,  Integer, default: 0,  required: true
    property :max_running_builds, Integer, default: 0,  required: true
    property :machines,           CommaSeparatedList,   required: true

    timestamps :at

    default_scope(:default).update(order: [:created_at.desc])

    def self.current
      self.first || Integrity.instance_manager.refresh
    end

    def self.metrics
      self.current.metrics
    end

    def self.log(machines, pending_load, running_load, load_requirement, load_capacity,
      load_deficit, machines_required, max_running_builds)
      pcount = Build.pending(:count)
      rcount = Build.running(:count)
      create(
        machines: machines,
        active_machines: machines.count,
        pending_builds: pcount.to_i,
        running_builds: rcount.to_i,
        pending_load: pending_load.to_i,
        running_load: running_load.to_i,
        load_requirement: load_requirement.to_i,
        load_capacity: load_capacity.to_i,
        load_deficit: load_deficit.to_i,
        machines_required: machines_required.to_i,
        max_running_builds: max_running_builds.to_i
      )
    end

    def metrics
      {
        pending_builds: pending_builds,
        running_builds: running_builds,
        machines:       active_machines,
        new_machines_requested: machines_required
      }
    end

    def usage
      {
        period: created_at.strftime('%Y-%m-%d %H:%M'),
        running: running_builds,
        pending: pending_builds,
        machines: active_machines
      }
    end
  end
end
