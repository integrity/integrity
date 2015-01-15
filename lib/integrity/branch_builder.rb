module Integrity
  class BranchBuilder
    include DataMapper::Resource

    property :id,                    Serial
    property :branch_id,             Integer, required: true
    property :build_id,              Integer, required: true
    property :active,                Boolean, default: false
    property :locked,                Boolean, default: false
    property :started_at,            DateTime
    property :completed_at,          DateTime

    belongs_to :branch
    belongs_to :build

    #build out scope so you can search for branch builder for a given branch
    def self.scope(query = :all, *conditions)
      send(query, *conditions)
    end

    def self.get_by_branch_id(query = :all)
      scope(query, branch_id:query)
    end


    #build first time you initialize
    def initialize
      build
    end

    #hook so when i make a push, if there exists a branchBuilder when for my commit's branch,
    #updates the diligence environment with new commit

    #also, deletes any other diligence builds on existing branch OR just updates the one that
    #was created through this view (this would be a departure from other convention, so far
    #old rebuild creates new build)
    def rebuild_environment
      if locked
        return false
      end

      #pause build on docker
      #save mysql database
      #rebuild and tell it to load the mysql shit somehow
    end

    #gets triggered when user clicks start button
    def build
      #build = builds.create(commit: commit, branch: branch, rebuild: rebuild)
      if active
        return false
      end

      build = builds.create(commit: latest_commit, branch: branch, rebuild: false)
      build.service_template = true
      build.run

      update(active: true)
    end


    def lock_state
      update(locked: true)
      # keeps it up
      # just flips a boolean
    end

    #only makes sense if lock is set. flips boolean so rebuild_environment hook works
    def unlock_state
      update(locked: true)
    end

    def turnoff
      build.kill!
    end


  end
end