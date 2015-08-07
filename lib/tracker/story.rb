require 'erb'
require 'i18n'

module Tracker
  class Story
    include DataMapper::Resource

    property :id,            Serial
    property :url,           String, :length => 255
    property :project_id,    Integer
    property :name,          Text, :lazy => false
    property :type,          String
    property :current_state, String
    property :commit_state,  String

    timestamps :at

    has n, :branches, 'Integrity::Branch'
    has n, :epics, :through => Resource

    has n, :story_owners
    has n, :owners, 'Tracker::User', :through => :story_owners, :via => :user

    belongs_to :requestor, 'Tracker::User'

    def self.create(tracker_story_id, tracker_story = nil)
      unless tracker_story
        tracker_story = TrackerWrapper.tracker_story(tracker_story_id)
      end
      return unless tracker_story

      story = Story.new
      story.requestor = Tracker::User.first id: tracker_story.requested_by_id

      tracker_story.owner_ids.each do |id|
        if user = Tracker::User.first(id: id)
          story.owners << user
        end
      end

      tracker_story.labels.map(&:id).each do |id|
        Integrity.logger.debug "MAPPING label id #{id}"
        if epic = Tracker::Epic.first(label_id: id)
          story.epics << epic
        end
      end

      story.id            = tracker_story.id
      story.url           = tracker_story.url
      story.project_id    = tracker_story.project_id
      story.name          = tracker_story.name
      story.type          = tracker_story.story_type
      story.current_state = tracker_story.current_state
      story.commit_state  = 'started'
      story.save

      story
    end

    def update
      tracker_story = TrackerWrapper.tracker_story(self.id)

      self.name          = tracker_story.name
      self.type          = tracker_story.story_type
      self.current_state = tracker_story.current_state
      self.requestor = Tracker::User.first id: tracker_story.requested_by_id

      self.owners = []
      tracker_story.owner_ids.each do |id|
        if user = Tracker::User.first(id: id)
          self.owners << user
        end
      end

      self.epics = []
      tracker_story.labels.map(&:id).each do |id|
        if epic = Tracker::Epic.first(label_id: id)
          self.epics << epic
        end
      end

      self.save
    end

    def self.update_from_hook(id, changes)
      Integrity.logger.debug "self.update_from_hook #{id}, #{changes.inspect}"
      if changes[:label_ids]
        tracker_story = TrackerWrapper.tracker_story(id)
        story = Tracker::Story.first(id: id)
        story.epics = []
        tracker_story.labels.map(&:id).each do |label_id|
          if epic = Tracker::Epic.first(label_id: label_id)
            story.epics << epic
          end
        end
        story.save
      end
    end

    def start
      self.commit_state = 'started'
      self.current_state  = 'started'
      TrackerWrapper.start_story(id)
    end

    def finish(build)
      self.commit_state = 'finished'
      self.current_state  = self.type == 'chore' ?  'accepted' : 'finished'
      TrackerWrapper.finish_story(id)
      send_pr_email(build)
    end

    def set_state(state)
      self.current_state = state
      self.save
    end

    def latest_build
      builds = []
      branches.each{|branch| builds << branch.last_build}
      builds = builds.compact.uniq
      builds.sort{|a,b| b.created_at <=> a.created_at}.last
    end

    def age
      ((Time.now - created_at) / 86400).to_i
    end

    def age_seconds
      (Time.now - created_at).to_i
    end

    def project
      if latest_branch = self.branches.last
        latest_branch.project
      end
    end

    def project_name
      project.try(:name)
    end

    def is_non_ci?
      project.try(:command) == 'rake'
    end

    def send_start_email(starter_name)
      SendGridWrapper.send_mail(self.requestor.email,
        I18n.t('story.start_email_subject', story_id: self.id),
        start_email_body(starter_name))
    end

    def send_failure_email
      SendGridWrapper.send_mail(self.owners.map(&:email),
        I18n.t('story.failure_email_subject', story_id: self.id),
        failure_email_body)
    end

    def pr_url
      return unless latest_build && (is_non_ci? || self.current_state == 'finished')

      pr_body = I18n.t('story.pr_body', commit_message: latest_build.commit.message,
                                              story_id: self.id,
                                             story_url: self.url)

      pr_link = I18n.t('story.pr_github_link', github_project_url: latest_build.branch.project.uri.to_s.gsub('git://', 'http://'),
                                                      branch_name: latest_build.branch.name,
                                                       story_name: self.name,
                                                          pr_body: pr_body)

      pr_link = URI.escape(pr_link)
    end

    def followers
      (owners << requestor).uniq.map(&:name).join(', ')
    end

    def display_class
      case current_state
      when 'started'
        'fa fa-cogs'
      when 'finished'
        'fa fa-code-fork'
      when 'delivered'
        'fa fa-gavel'
      else
      end
    end

    private

    def send_pr_email(build)
      SendGridWrapper.send_mail(self.owners.map(&:email),
        I18n.t('story.pr_email_subject', story_id: self.id),
        pr_email_body(build))
    end

    def start_email_body(starter_name)
      story_name = self.name
      story_link = URI.escape(self.url)
      template = ERB.new(File.read("./lib/app/views/tracker_story_start_email.erb"))
      html_content = template.result(binding)
    end

    def failure_email_body
      story_owner_name = owners.join(', ')
      story_branch_name = latest_build.branch.name
      story_link = URI.escape(self.url)
      template = ERB.new(File.read("./lib/app/views/build_failure_email.erb"))
      html_content = template.result(binding)
    end

    def pr_email_body(build)
      pr_body = I18n.t('story.pr_body', commit_message: build.commit.message,
                                              story_id: self.id,
                                             story_url: self.url)

      pr_link = I18n.t('story.pr_github_link', github_project_url: build.branch.project.uri.to_s.gsub('git://', 'http://'),
                                                      branch_name: build.branch.name,
                                                       story_name: self.name,
                                                          pr_body: pr_body)

      pr_link = URI.escape(pr_link)
      template = ERB.new(File.read("./lib/app/views/github_pr_email.erb"))
      html_content = template.result(binding)
    end
  end
end
