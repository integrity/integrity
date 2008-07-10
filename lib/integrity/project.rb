require 'dm-validations'

module Integrity
  class Project
    include DataMapper::Resource

    property :id,       Integer,  :serial => true
    property :name,     String
    property :uri,      String
    property :branch,   String,   :default => "master"
    property :command,  String,   :default => "rake"
    property :public,   Boolean,  :default => true
    
    def permalink
      @permalink ||= name.downcase.gsub(/\s+/, '_')
    end
  end
end
