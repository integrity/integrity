module Integrity
  class Build
    include DataMapper::Resource

    property :id,           Serial
    property :output,       Text,     :default => "", :lazy => false
    property :successful,   Boolean,  :default => false
    property :commit_id,    Integer,  :nullable => false
    property :started_at,   DateTime
    property :completed_at, DateTime

    timestamps :at

    belongs_to :commit, :class_name => "Integrity::Commit",
                        :child_key => [:commit_id]

    def self.pending
      all(:started_at => nil)
    end

    def pending?
      started_at.nil?
    end

    def building?
      ! started_at.nil? && completed_at.nil?
    end

    def failed?
      !successful?
    end

    def status
      case
      when pending?    then :pending
      when building?   then :building
      when successful? then :success
      when failed?     then :failed
      end
    end
  end
end
