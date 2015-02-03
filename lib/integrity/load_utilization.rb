module Integrity
  class LoadUtilization
    include DataMapper::Resource

    property :id,                 Serial
    property :pending_builds,     Integer, default: 0, required: true
    property :running_builds,     Integer, default: 0, required: true
    property :active_machines,    Integer, default: 0, required: true
    property :pending_load,       Integer, default: 0, required: true
    property :running_load,       Integer, default: 0, required: true
    property :load_requirement,   Integer, default: 0, required: true
    property :load_capacity,      Integer, default: 0, required: true
    property :load_deficit,       Integer, default: 0, required: true
    property :machines_required,  Integer, default: 0, required: true
    property :max_running_builds, Integer, default: 0, required: true

    timestamps :at

    default_scope(:default).update(order: [:created_at.desc])


    def self.log(machines, pending_load, running_load, load_requirement, load_capacity,
      load_deficit, machines_required, max_running_builds)
      pcount = Build.pending(:count)
      rcount = Build.running(:count)
      create(
        pending_builds: pcount,
        running_builds: rcount,
        active_machines: machines,
        pending_load: pending_load,
        running_load: running_load,
        load_requirement: load_requirement,
        load_capacity: load_capacity,
        load_deficit: load_deficit,
        machines_required: machines_required,
        max_running_builds: max_running_builds
      )
    end

    def metrics
      {
        pending_builds: pending_builds,
        running_builds: running_builds,
        machines:       active_machines.count,
        new_machines_requested: machines_required
      }
    end


  end
end