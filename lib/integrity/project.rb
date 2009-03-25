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
      commit_identifier = head_of_remote_repo if commit_identifier == "HEAD"
      commit = find_or_create_commit_with_identifier(commit_identifier)
      commit.queue_build
    end

    def push(payload)
      payload = parse_payload(payload)
      raise ArgumentError unless valid_payload?(payload)

      commits =
        if Integrity.config[:build_all_commits]
          payload["commits"]
        else
          [ payload["commits"].first ]
        end

      commits.each do |commit_data|
        create_commit_from(commit_data)
        build(commit_data["id"])
      end
    end

    def last_commit
      commits.first(:project_id => id, :order => [:committed_at.desc])
    end

    def last_build
      warn "Project#last_build is deprecated, use Project#last_commit (#{caller[0]})"
      last_commit
    end

    def previous_commits
      commits.all(:project_id => id, :order => [:committed_at.desc]).tap {|commits| commits.shift }
    end

    def previous_builds
      warn "Project#previous_builds is deprecated, use Project#previous_commits (#{caller[0]})"
      previous_commits
    end

    def status
      last_commit && last_commit.status
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

    def config_for(notifier)
      notifier = notifiers.first(:name => notifier.to_s.split(/::/).last, :project_id => id)
      notifier.blank? ? {} : notifier.config
    end

    def notifies?(notifier)
      !notifiers.first(:name => notifier.to_s.split(/::/).last, :project_id => id).blank?
    end

    def enable_notifiers(*args)
      Notifier.enable_notifiers(id, *args)
    end

    private
      def find_or_create_commit_with_identifier(commit_identifier)
        # We abuse +committed_at+ here setting it to Time.now because we use it
        # to sort (for last_commit and previous_commits). I don't like this
        # very much, but for now it's the only solution I can find.
        #
        # This also creates a dependency, as now we *always* have to update the
        # +committed_at+ field after building to ensure the date is correct :(
        #
        # This might also make your commit listings a little jumpy, if some
        # commits change place every time a build finishes =\
        commits.first_or_create({ :identifier => commit_identifier, :project_id => id }, :committed_at => Time.now)
      end

      def head_of_remote_repo
        SCM.new(uri, branch).head
      end

      def create_commit_from(data)
        commits.create(:identifier   => data["id"],
                       :author       => "#{data["author"]["name"]} <#{data["author"]["email"]}>",
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

      def valid_payload?(payload)
        payload && payload["ref"].to_s.include?(branch) &&
                               !payload["commits"].nil? &&
                               !payload["commits"].to_a.empty?
      end

      def parse_payload(payload)
        JSON.parse(payload.to_s)
      rescue JSON::ParserError
        false
      end
  end
end
