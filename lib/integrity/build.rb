module Integrity
  class Build
    include DataMapper::Resource

    property :id,           Integer,  :serial => true
    property :output,       Text,     :default => "", :lazy => false
    property :successful,   Boolean,  :default => false
    property :commit_id,    Integer,  :nullable => false
    property :created_at,   DateTime
    property :updated_at,   DateTime
    property :started_at,   DateTime
    property :completed_at, DateTime

    belongs_to :commit, :class_name => "Integrity::Commit"

    def self.pending
      all(:started_at => nil)
    end

    def self.queue(commit)
      commit.update_attributes(:build => new)

      # Build on foreground (this will move away, I promise)
      ProjectBuilder.build(commit)
    end

    def pending?
      started_at.nil?
    end

    def failed?
      !successful?
    end

    def status
      case
      when pending?    then :pending
      when successful? then :success
      when failed?     then :failed
      end
    end

    def start!(time=Time.now)
      self.started_at = time
    end

    def complete!(time=Time.now)
      self.completed_at = time
    end
  end
end
