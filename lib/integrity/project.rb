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

    has n, :commits, :class_name => "Integrity::Commit"
    has n, :notifiers, :class_name => "Integrity::Notifier"

    before :save, :set_permalink
    before :destroy, :delete_code

    validates_is_unique :name

    def self.only_public_unless(condition)
      if condition
        all
      else
        all(:public => true)
      end
    end
    
    def build(commit_identifier="HEAD")
      commit = commits.first(:identifier => commit_identifier, :project_id => id) || last_commit
      commit.queue_build
    end

    def push(payload)
      payload = JSON.parse(payload || "")
      return unless payload["ref"] =~ /#{branch}/
      return if payload["commits"].nil?
      return if payload["commits"].empty?
        
      commits = if Integrity.config[:build_all_commits]
        payload["commits"]
      else
        [payload["commits"].first]
      end
      
      commits.each do |commit_data|
        create_commit_from(commit_data)
        build(commit_data['id'])
      end
    end

    def last_commit
      commits.first(:project_id => id, :order => [:committed_at.desc])
    end
    
    def last_build
      warn "Project#last_build is deprecated, use Project#last_commit"
      last_commit
    end

    def previous_commits
      commits.all(:project_id => id, :order => [:committed_at.desc]).tap {|commits| commits.shift }
    end
    
    def previous_builds
      warn "Project#previous_builds is deprecated, use Project#previous_commits"
      previous_commits
    end

    def status
      last_commit && last_commit.status
    end

    def public=(flag)
      attribute_set(:public, case flag
        when "1", "0" then flag == "1"
        else !!flag
      end)
    end

    def config_for(notifier)
      notifier = notifiers.first(:name => notifier.to_s.split(/::/).last)
      notifier.blank? ? {} : notifier.config
    end

    def notifies?(notifier)
      !notifiers.first(:name => notifier.to_s.split(/::/).last).blank?
    end

    def enable_notifiers(*args)
      Notifier.enable_notifiers(id, *args)
    end

    private
      def create_commit_from(data)
        commits.create(:identifier   => data["id"],
                       :author       => data["author"],
                       :message      => data["message"],
                       :committed_at => data["timestamp"])
      end
    
      def set_permalink
        self.permalink = (name || "").downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, "")
      end

      def delete_code
        commits.all(:project_id => id).destroy!
        ProjectBuilder.new(self).delete_code
      rescue SCM::SCMUnknownError => error
        Integrity.log "Problem while trying to deleting code: #{error}"
      end
  end
end