require 'erb'
require 'i18n'

module Tracker
  class Story
    include DataMapper::Resource

    property :id,            Serial
    property :url,           String, :length => 255
    property :pr_url,        String, :length => 255
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
      TrackerWrapper.set_state(id, current_state)
      self.save
    end

    def finish(pr_url)
      self.current_state  = self.type == 'chore' ?  'started' : 'finished'
      self.pr_url = pr_url
      TrackerWrapper.set_state(id, current_state)
      self.save
    end

    def deliver
      self.current_state = self.type == 'chore' ?  'accepted' : 'delivered'
      self.save
      send_delivered_email
      TrackerWrapper.set_state(id, current_state)
      Tracker::StoryMerge.create(id)
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

    def branch_name
      branches.last.try(:name) || Tracker::Helper.generate_branch_name_from_story(self)
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

    def create_pr_url
      return unless latest_build

      pr_body = I18n.t('story.pr_body', commit_message: latest_build.commit.message,
                                              story_id: self.id,
                                             story_url: self.url)

      pr_link = I18n.t('story.pr_github_link', github_project_url: latest_build.branch.project.uri.to_s.gsub('git://', 'http://'),
                                                      branch_name: latest_build.branch.name,
                                                       story_name: self.name,
                                                          pr_body: pr_body)

      URI.escape(pr_link)
    end

    def followers
      (owners << requestor).uniq.map(&:name).join(', ')
    end

    def age_class
      case
      when age < 2
        'epic-icon-green'
      when age < 5
        'epic-icon-orange'
      else
        'epic-icon-red'
      end
    end

    def display_class
      case current_state
      when 'started'
        'fa fa-cogs ' + age_class
      when 'finished'
        'fa fa-code-fork ' + age_class
      when 'delivered'
        'fa fa-gavel ' + age_class
      else
      end
    end

    private

    def start_email_body(starter_name)
      story_name = self.name
      story_link = URI.escape(self.url)
      template = ERB.new(File.read("./lib/app/views/tracker_emails/story_start_email.erb"))
      template.result(binding)
    end

    def failure_email_body
      story_owner_name = owners.join(', ')
      story_branch_name = latest_build.branch.name
      story_link = URI.escape(self.url)
      template = ERB.new(File.read("./lib/app/views/tracker_emails/build_failure_email.erb"))
      template.result(binding)
    end

    def pr_email_body
      pr_link = create_pr_url
      template = ERB.new(File.read("./lib/app/views/tracker_emails/github_pr_email.erb"))
      template.result(binding)
    end

    def send_pr_email
      SendGridWrapper.send_mail(self.owners.map(&:email),
        I18n.t('story.pr_email_subject', story_id: self.id),
        pr_email_body)
    end

    def delivered_email_body
      story_name = self.name
      story_owners = owners.map(&:name).join(', ')
      story_link = URI.escape(self.url)
      template = ERB.new(File.read("./lib/app/views/tracker_emails/story_delivered_email.erb"))
      template.result(binding)
    end

    def send_delivered_email
      SendGridWrapper.send_mail(self.requestor.email,
        I18n.t('story.delivered_email_subject', story_id: self.id),
        delivered_email_body)
    end
  end
end
