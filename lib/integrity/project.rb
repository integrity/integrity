module Integrity
  class Project
    include DataMapper::Resource

    property :id,       Integer,  :serial => true
    property :name,     String,   :nullable => false
    property :uri,      URI,      :nullable => false, :length => 255
    property :branch,   String,   :nullable => false, :default => "master"
    property :command,  String,   :nullable => false, :length => 255, :default => "rake"
    property :public,   Boolean,  :default => true
    
    has n, :builds, :class_name => "Integrity::Build"

    def build
      build = Builder.new(uri, branch, command).build
      build.project = self
      build.save
    end
  end
end
