require "integrity/project/notifiers"
require "integrity/project/push"

module Integrity
  class Project
    include DataMapper::Resource
    include Bob::Buildable
    include Notifiers, Push

    property :id,         Serial
    property :name,       String,   :nullable => false
    property :permalink,  String
    property :uri,        URI,      :nullable => false, :length => 255
    property :branch,     String,   :nullable => false, :default => "master"
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

    def kind
      :git
    end

    alias_method :build_script, :command

    def start_building(commit_id, commit_info)
      @commit = commits.first_or_create({:identifier => commit_id},
        commit_info.update(:project_id => id))
      @build  = Build.new(:started_at => Time.now)
      @commit.update_attributes(:build => @build)
    end

    def finish_building(commit_id, status, output)
      @build.update_attributes(
        :successful => status, :output => output,
        :completed_at => Time.now) if @build
      enabled_notifiers.each { |notifier| notifier.notify_of_build(@build) }
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
