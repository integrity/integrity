require 'hashie'

class TrackerWrapper
  @@config =
    Hashie::Mash.new(
      api_token: nil,
      project_id: nil,
      client_timeout: nil,
    )

  def self.config
    @@config
  end

  def self.configure
    yield @@config

    [
      %w[api_token],
      %w[project_id],
      %w[client_timeout],
    ].each{|keys| !keys.reduce(@@config){|memo,key| memo && memo[key] }.nil? || raise("TrackerWrapper.config.#{keys.join('.')} is required") }
  end

  def self.tracker_story(story_id)
    project.stories.find(story_id)
  end

  def self.finish_story(story_id)
    tracker_story = project.stories.find(story_id)
    tracker_story.story_type == 'chore' ? tracker_story.update({current_state: 'accepted'}) : tracker_story.update({current_state: 'finished'})
  end

  private

  def self.project
    PivotalTracker::Client.token = config.api_token
    PivotalTracker::Client.timeout = config.client_timeout
    project = PivotalTracker::Project.find(config.project_id)
  end
end
