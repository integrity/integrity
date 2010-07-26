module Integrity
  class Build
    include DataMapper::Resource

    HUMAN_STATUS = {
      :success  => "Built %s successfully",
      :failed   => "Built %s and failed",
      :pending  => "%s hasn't been built yet",
      :building => "%s is building"
    }

    property :id,           Serial
    property :project_id,   Integer   # TODO :nullable => false
    property :output,       Text,     :default => "", :length => 1048576
    property :successful,   Boolean,  :default => false
    property :started_at,   DateTime
    property :completed_at, DateTime

    timestamps :at

    belongs_to :project
    has 1,     :commit

    before :destroy do
      commit.destroy!
    end

    def run
      Integrity.config.builder.enqueue(self)
    end

    def run!
      Builder.build(self, Integrity.config.directory, Integrity.logger)
    end

    def notify
      project.enabled_notifiers.each { |n| n.notify(self) }
    end

    def successful?
      successful == true
    end

    def failed?
      ! successful?
    end

    def building?
      ! started_at.nil? && completed_at.nil?
    end

    def pending?
      started_at.nil?
    end

    def completed?
      ! pending? && ! building?
    end

    def repo
      project.repo
    end

    def command
      project.command
    end

    def sha1
      commit.identifier
    end

    def sha1_short
      unless sha1
        return "This commit"
      end

      sha1[0..6]
    end

    def message
      commit.message || "message not loaded"
    end

    def author
      (commit.author || Author.unknown).name
    end

    def committed_at
      commit.committed_at
    end

    def status
      case
      when building?   then :building
      when pending?    then :pending
      when successful? then :success
      when failed?     then :failed
      end
    end

    def human_status
      HUMAN_STATUS[status] % sha1_short
    end
  end
end
