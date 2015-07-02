require 'erb'
require 'i18n'

module Tracker
  class Story
    include DataMapper::Resource

    property :id,            Serial
    property :url,           String
    property :project_id,    Integer
    property :name,          Text, :lazy => false
    property :type,          String
    property :current_state, String
    property :commit_state,  String

    timestamps :at

    has n, :branches, 'Integrity::Branch'
    has n, :users, :through => Resource

    def self.create(tracker_story_id, tracker_story = nil)
      unless tracker_story
        tracker_story = TrackerWrapper.tracker_story(tracker_story_id)
      end
      return unless tracker_story

      story = Story.new

      user_ids = []
      user_ids << tracker_story.follower_ids << tracker_story.owner_ids << tracker_story.requested_by_id
      user_ids = user_ids.flatten.uniq

      user_ids.each do |id|
        if user = Tracker::User.first(id: id)
          story.users << user
        end
      end

      story.id            = tracker_story.id
      story.url           = tracker_story.url
      story.project_id    = tracker_story.project_id
      story.name          = tracker_story.name
      story.type          = tracker_story.story_type
      story.current_state = tracker_story.current_state
      self.commit_state   = 'started'
      story.save
      story
    end

    def start
      self.commit_state = 'started'
      self.current_state  = 'started'
      TrackerWrapper.start_story(id)
      self.save
    end

    def finish(build)
      self.commit_state = 'finished'
      self.current_state  = self.story_type == 'chore' ?  'accepted' : 'finished'
      TrackerWrapper.finish_story(id)
      send_pr_email(build)
      self.save
    end

    def followers
      users.map(&:name).join(', ')
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

    private

    def send_pr_email(build)
      SendGridWrapper.send_mail(self.users.map(&:email),
        email_subject,
        email_body(build))
    end

    def email_subject
      I18n.t('story.email_subject', story_id: self.id)
    end

    def email_body(build)
      pr_body = I18n.t('story.pr_body', commit_message: build.commit.message,
                                              story_id: self.id,
                                             story_url: self.url)

      pr_link = I18n.t('story.github_pr_link', github_project_url: build.branch.project.uri.to_s.gsub('git://', 'http://'),
                                                      branch_name: build.branch.name,
                                                       story_name: self.name,
                                                          pr_body: pr_body)

      pr_link = URI.escape(pr_link)
      template = ERB.new(File.read("./lib/app/views/github_pr_email.erb"))
      html_content = template.result(binding)
    end
  end
end
