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

    #
    # Deprecated methods
    #
    def short_commit_identifier
      warn "Build#short_commit_identifier is deprecated, use Commit#short_identifier (#{caller[0]})"
      commit.short_identifier
    end

    def commit_identifier
      warn "Build#commit_identifier is deprecated, use Commit#identifier (#{caller[0]})"
      commit.identifier
    end

    def commit_author
      warn "Build#commit_author is deprecated, use Commit#author (#{caller[0]})"
      commit.author
    end

    def commit_message
      warn "Build#commit_message is deprecated, use Commit#message (#{caller[0]})"
      commit.message
    end

    def commited_at
      warn "Build#commited_at is deprecated, use Commit#committed_at (#{caller[0]})"
      commit.committed_at
    end

    def project_id
      warn "Build#project_id is deprecated, use Commit#project_id (#{caller[0]})"
      commit.project_id
    end

    def commit_metadata
      warn "Build#commit_metadata is deprecated, use the different methods in Commit instead (#{caller[0]})"
      { :message => commit.message,
        :author  => commit.author,
        :date    => commit.committed_at }
    end
  end
end
