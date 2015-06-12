require 'rconfig'

class Configuration
  attr_accessor :api_token,
                :project_id,
                :client_timeout
end

class TrackerWrapper
  def self.tracker_story(story_id)
    project.stories.find(story_id)
  end

  def self.finish_story(story_id)
    tracker_story = project.stories.find(story_id)
    tracker_story.story_type == 'chore' ? tracker_story.update({current_state: 'accepted'}) : tracker_story.update({current_state: 'finished'})
  end

  private

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.project
    PivotalTracker::Client.token = config.api_token
    PivotalTracker::Client.timeout = config.client_timeout
    project = PivotalTracker::Project.find(config.project_id)
  end
end
