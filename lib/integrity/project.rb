require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :required => true, :unique => true
    property :permalink,  String
    property :uri,        URI,      :required => true, :length => 255
    property :branch,     String,   :required => true, :default => "master"
    property :command,    String,   :required => true, :length => 255, :default => "rake"
    property :public,     Boolean,  :default  => true

    timestamps :at

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

    def fork(new_branch)
      Project.create(
        :name    => "#{name} (#{new_branch})",
        :uri     => uri,
        :branch  => new_branch,
        :command => command,
        :public  => public?
      )
    end

    def github?
      uri.to_s.include?("github.com")
    end

    # TODO lame, there is got to be a better way
    def sorted_builds
      builds(:order => [:created_at.desc])
    end

    def last_build
      sorted_builds.first
    end

    def blank?
      last_build.nil?
    end

    def status
      blank? ? :blank : last_build.status
    end

    def human_status
      ! blank? && last_build.human_status
    end

    def public=(v)
      return attribute_set(:public, v == "1") if %w[0 1].include?(v)
      attribute_set(:public, !!v)
    end

    private
      def set_permalink
        attribute_set(:permalink,
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
