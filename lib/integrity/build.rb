module Integrity
  class Build
    include DataMapper::Resource

    property :id,       Integer,  :serial => true
    property :output,   Text,     :nullable => false, :default => ''
    property :error,    Text,     :nullable => true,  :default => ''
    property :commit,   Yaml,     :nullable => false
    property :status,   Boolean,  :nullable => false, :default => false
    
    belongs_to :project, :class_name => "Integrity::Project"

    def success?
      status
    end

    def failure?
      !success?
    end

    def human_readable_status
      success? ? 'Successful' : 'Fail'
    end
  end
end
