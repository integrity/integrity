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
      when :success  then "Built #{commit.short_identifier} successfully"
      when :failed   then "Built #{commit.short_identifier} and failed"
      when :pending  then "This commit hasn't been built yet"
      when :building then "#{commit.short_identifier} is building"
      end
    end
  end
end
