require 'ostruct'

module Integrity
  class Build
    include DataMapper::Resource

    property :id,                Integer,  :serial => true
    property :output,            Text,     :nullable => false, :default => ''
    property :successful,        Boolean,  :nullable => false, :default => false
    property :commit_identifier, String,   :nullable => false
    property :commit_metadata,   Yaml,     :nullable => false, :lazy => false
    property :created_at,        DateTime
    property :updated_at,        DateTime

    belongs_to :project, :class_name => "Integrity::Project"

    def failed?
      !successful?
    end

    def status
      successful? ? :success : :failed
    end

    def human_readable_status
      successful? ? 'Build Successful' : 'Build Failed'
    end

    def short_commit_identifier
      sha1?(commit_identifier) ? commit_identifier[0..6] : commit_identifier
    end

    def commit_author
      @author ||= begin
        commit_metadata[:author] =~ /^(.*) <(.*)>$/
        OpenStruct.new(:name => $1.strip, :email => $2.strip, :full => commit_metadata[:author])
      end
    end

    def commit_message
      commit_metadata[:message]
    end

    def commited_at
      case commit_metadata[:date]
        when String then Time.parse(commit_metadata[:date])
        else commit_metadata[:date]
      end
    end

    private
      def sha1?(string)
        string =~ /^[a-f0-9]{40}$/
      end
  end
end
