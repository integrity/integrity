require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :nullable => false
    property :permalink,  String
    property :uri,        URI,      :nullable => false, :length => 255
    property :branch,     String,   :nullable => false, :default => "master"
    property :command,    String,   :nullable => false, :length => 255, :default => "rake"
    property :public,     Boolean,  :default  => true

    timestamps :at

    default_scope(:default).update(:order => [:name.asc])

    has n, :builds
    has n, :notifiers

    before :save, :set_permalink
    before :destroy do builds.destroy! end

    validates_is_unique :name

    def build(commit)
      BuildableProject.new(self, commit).build
    end

    def last_build
      builds.first(:order => [:created_at.desc])
    end

    def previous_builds
      builds.all(:id.not => last_build.id, :order => [:created_at.desc])
    end

    def building?
      builds.count(:started_at.not => nil, :completed_at => nil)
    end

    def blank?
      builds.count.zero?
    end

    def status
      blank? ? :blank : last_build.status
    end

    def human_status
      last_build && last_build.human_status
    end

    def public=(flag)
      attribute_set(:public, case flag
        when "1", "0" then flag == "1"
        else !!flag
      end)
    end

    private
      def set_permalink
        attribute_set(:permalink, (name || "").downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, ""))
      end
  end
end
