require 'dm-validations'

module Integrity
  class Project
    include DataMapper::Resource

    property :id,       Integer,  :serial => true
    property :name,     String
    property :uri,      String
    property :branch,   String
    property :command,  String
    property :public,   Boolean
    
    def permalink
      @permalink ||= name.downcase.gsub(/\s+/, '_')
    end
  end
end
