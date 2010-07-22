module Integrity
  class Build
    include DataMapper::Resource

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
      Builder.build(self, Integrity.logger)
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
      !pending? && !building?
    end

    def sha1
      commit.identifier
    end

    # TODO
    def sha1_short
      if commit
        commit.short_identifier
      else
        "This commit"
      end
    end

    def message
      commit.message
    end

    def author
      commit.author.name
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
      case status
      when :success  then "Built #{sha1_short} successfully"
      when :failed   then "Built #{sha1_short} and failed"
      when :pending  then "#{sha1_short} hasn't been built yet"
      when :building then "#{sha1_short} is building"
      end
    end
  end
end
