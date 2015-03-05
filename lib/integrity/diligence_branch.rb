module Integrity
  class DiligenceBranch
    include DataMapper::Resource

    property :id,                    Serial
    property :active,                Boolean, default: false
    property :locked,                Boolean, default: false
    property :locked_at,             DateTime
    property :created_at,            DateTime
    property :updated_at,            DateTime

    belongs_to :branch, unique:true
    belongs_to :build, unique:true, required: false
    belongs_to :commit, required: false

    def self.deactivate(build_id)
      db =  DiligenceBranch.first(build_id: build_id)
      if db
        db.update(active: false)
      end
    end

    def rebuild_environment
      if !locked && active && !latest_commit?
        stop
        start
      end
    end

    def start
      if active
        return false
      end

      if !locked
        self.commit = Commit.last(branch: branch.name)
        self.locked_at = Time.now
      end

      self.build = branch.project.build(commit, true, 'server')
      self.active = true
      self.save
    end

    def stop
      build.cancel_with_reason('Diligence', 'New Commit to Branch', 'DiligenceBranch::stop')
    end

    def latest_commit?
      self.commit.identifier == Commit.last(branch: branch.name).identifier
    end

    def flip_lock
      update(locked: !locked)
      rebuild_environment
    end
  end
end
