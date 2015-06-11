require 'erb'

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

    def self.create(tracker_story_id)
      tracker_story = TrackerWrapper.tracker_story(tracker_story_id)
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
        'ops+honesty_robot@grnds.com',
        email_subject,
        email_body(build))
    end

    def email_subject
      'Story ' + self.id.to_s + ' is ready to PR'
    end

    def email_body(build)
      pr_link = generate_pr_url(build)
      template = ERB.new(File.read("./lib/app/views/github_pr_email.erb"))
      html_content = template.result(binding)
    end

    def generate_pr_url(build)
      github_pr_link = build.branch.project.uri.to_s.gsub('git://', 'http://')
      github_pr_link += '/compare/master...' + build.branch.name
      github_pr_link += '?title=' + URI.escape(self.name)
      body = build.commit.message + "\n\n"
      body += '[Tracker #' + self.id.to_s + '](' + self.url + ')'
      github_pr_link += '&body=' + URI.escape(body)
    end
  end
end
