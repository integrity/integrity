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
      assert_jarvis_branch!
      # TODO the pancakes object should obviously not be re-created everytime this method is called
      Integrity::Pancakes::Stack.new_with_jarvis_branch(branch: self)
    end

    def make_pancakes
      assert_jarvis_branch!

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
      destroy_pancakes
    end

    def start_tracking
      pk = make_pancakes
      pk.orchestrate
    end

    def update_pancakes
      destroy_pancakes
      start_tracking
    end

    private

    def destroy_pancakes
      Pancakes::Freezer.remove(pancakes)
      pancakes.destroy
    end

    # pancakes only work for jarvis branches as of the time i wrote this
    def assert_jarvis_branch!
      if project.name != 'jarvis'
        raise 'pancakes only work for jarvis so far'
      end
    end
  end
end
