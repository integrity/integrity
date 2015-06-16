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
      tracker_story = tracker_story || TrackerWrapper.tracker_story(tracker_story_id)
      return unless tracker_story

      story = Story.new

      user_names = []
      user_names << tracker_story.requested_by << tracker_story.owned_by
      user_names = user_names.uniq
      user_names.each do |name|
        user = Tracker::User.first(name: name)
        if user
          story.users << user unless story.users.include?(user)
        end
      end

      story.id            = tracker_story.id
      story.url           = tracker_story.url
      story.project_id    = tracker_story.project_id
      story.name          = tracker_story.name
      story.type          = tracker_story.story_type
      story.current_state = tracker_story.current_state
      story.save
      story
    end

    def finish(build)
      self.commit_state = 'finished'
      TrackerWrapper.finish_story(id)
      send_pr_email(build)
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
