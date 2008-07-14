module Integrity
  class Project
    include DataMapper::Resource

    property :id,         Integer,  :serial => true
    property :name,       String,   :nullable => false
    property :permalink,  String
    property :uri,        URI,      :nullable => false, :length => 255
    property :branch,     String,   :nullable => false, :default => "master"
    property :command,    String,   :nullable => false, :length => 255, :default => "rake"
    property :public,     Boolean,  :default => true
    property :building,   Boolean,  :default => false
    property :created_at, DateTime
    property :updated_at, DateTime
    
    has n, :builds, :class_name => "Integrity::Build"
    before :save, :set_permalink

    def build
      return if building?
      update_attributes(:building => true)
      Builder.new(self).build
    ensure
      update_attributes(:building => false)
    end
    
    def last_build
      @last_build ||= builds.first(:order => [:created_at.desc])
    end
    
    def previous_builds
      @previous_builds ||= builds.all(:order => [:created_at.desc], :offset => 1, :limit => builds.count - 1)
    end
    
    private
    
      def set_permalink
        self.permalink = (name || "").downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/i, "-")
      end
  end
end
