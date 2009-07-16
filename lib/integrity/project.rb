require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :nullable => false
    property :permalink,  String
    property :uri,        URI,      :nullable => false, :length => 255
    property :scm,        String,   :nullable => false, :default => "git"
    property :branch,     String,   :nullable => true,  :default => ""
    property :command,    String,   :nullable => false, :length => 255, :default => "rake"
    property :public,     Boolean,  :default => true

    timestamps :at

    default_scope(:default).update(:order => [:name.asc])

    has n, :commits, :class_name => "Integrity::Commit"
    has n, :notifiers, :class_name => "Integrity::Notifier"

    before :save, :set_permalink

    before :destroy do
      commits.destroy!
    end

    validates_is_unique :name

    def build(commit)
      BuildableProject.new(self, commit).build
    end

    def last_commit
      commits.first(:project_id => id, :order => [:committed_at.desc])
    end

    def previous_commits
      commits.all(:project_id => id, :order => [:committed_at.desc]).
        tap {|commits| commits.shift }
    end

    def building?
      commits.any? { |c| c.building? }
    end

    def status
      last_commit ? last_commit.status : :blank
    end

    def human_readable_status
      last_commit && last_commit.human_readable_status
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
