module Integrity
  class Branch
    include DataMapper::Resource
    include Integrity::WebUtils

    property :id,         Serial
    property :project_id, Integer, required: true
    property :name,       String,  required: true, length: 255
    property :permalink,  String,  length: 255
    property :last_build_id, Integer, required: false
    property :pancaked,        Boolean, required: true, default: false
    property :pancakes_locked, Boolean, required: true, default: false
    # pancakes_serialno is used to uniquely identify each instance of a pancake stack.
    # this avoids races in fleet between deleting an old stack and bringing up a new one.
    property :pancakes_serialno, Integer, required: true, default: 1

    timestamps :at

    has n, :builds
    belongs_to :project
    belongs_to :last_build, 'Build'

    before :save, :set_permalink

    before :destroy do
      builds.destroy!
    end

    delegate :repo, to: :project
    delegate :status, :human_status, :human_duration, :successful?, :failed?, :pending?, :building?, to: :last_build, allow_nil: true

    # @return 30 most recent green branches
    def self.not_pancaked
      # project_id 10 jarvis
      # project_id  3 tim
      # project_id  2 frick
      branches = Integrity::Branch.all(project_id: [2, 3, 10], pancaked: false)
      branches.select do |x|
        lb = x.last_build
        lb && lb.successful == true && lb.state == nil
      end
        .sort{|a,b| b.last_build.completed_at <=> a.last_build.completed_at }
        .take(30)
    end

    def self.pancaked
      Integrity::Branch.all(order: :last_build_id.desc, pancaked: true)
    end

    def blank?
      last_build.nil?
    end

    def sorted_builds
      builds(order: [:created_at.desc, :id.desc])
    end

    def builds_before(build)
      sorted_builds.all(:created_at.lt => build.created_at)
    end

    def most_recent_build
      builds.first(order: :created_at.desc)
    end

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # Pancakes # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    def should_update_pancakes?
      self.pancaked? && !self.pancakes_locked?
    end

    def pancakes
      # TODO the pancakes object should obviously not be re-created everytime this method is called
      Pancakes::StackMaker.new_with_integrity_branch(self)
    end

    def make_pancakes
      self.pancaked = true
      self.pancakes_locked = false
      self.pancakes_serialno += 1

      if save
        return pancakes
      else
        raise "couldn't save branch trying to make pancakes"
      end
    end

    def flip_lock
      self.pancakes_locked = !self.pancakes_locked
      save
    end

    def stop_tracking
      self.pancaked = false
      self.pancakes_locked = false
      save
      pancakes.destroy
      sleep 3  # to avoid a race, give the mysql container a chance to freeze stuff before we delete it.
      pancakes.remove_from_freezer
    end

    def start_tracking
      pk = make_pancakes
      pk.create
    end

    def update_pancakes
      pancakes.destroy_async
      start_tracking
    end
  end
end
