require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :required => true
    property :permalink,  String
    property :uri,        URI,      :required => true, :length => 255
    property :branch,     String,   :required => true, :default => "master"
    property :command,    String,   :required => true, :length => 255, :default => "rake"
    property :public,     Boolean,  :default  => true

    timestamps :at

    validates_is_unique :name

    default_scope(:default).update(:order => [:name.asc])

    has n, :builds
    has n, :notifiers

    before :save, :set_permalink

    before :destroy do
      builds.destroy!
    end

    def build(commit)
      BuildableProject.new(self, commit).build
    end

    # TODO lame, there is got to be a better way
    def sorted_builds
      builds(:order => [:updated_at.asc])
    end

    def status
      return :blank if blank?
      sorted_builds.last.status
    end

    def blank?
      sorted_builds.last.nil?
    end

    def human_status
      return if blank?
      last_build.human_status
    end

    def public=(v)
      value =
        if %w[0 1].include?(v)
          v == "1"
        else
          !! v
        end

      attribute_set(:public, v)
    end

    private
      def set_permalink
        set_attribute(:permalink,
          (name || "").
          downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, "")
        )
      end
  end
end
