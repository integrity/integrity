module Integrity
  class Build
    include DataMapper::Resource

    property :id,         Integer,  :serial => true
    property :output,     Text,     :nullable => false, :default => ''
    property :successful, Boolean,  :nullable => false, :default => false
    property :created_at, DateTime
    property :updated_at, DateTime
    property :commit_identifier, String, :nullable => false
    property :commit_metadata,   Yaml,   :nullable => false

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
  end
end
