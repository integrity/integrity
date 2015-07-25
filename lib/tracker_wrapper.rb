require 'hashie'

class TrackerWrapper
  @@config =
    Hashie::Mash.new(
      api_token: nil,
      project_id: nil,
    )

  def self.config
    @@config
  end

  def self.configure
    yield @@config

    [
      %w[api_token],
      %w[project_id],
    ].each{|keys| !keys.reduce(@@config){|memo,key| memo && memo[key] }.nil? || raise("TrackerWrapper.config.#{keys.join('.')} is required") }
  end

  def self.tracker_story(story_id)
    project.story(story_id)
  end

  def self.tracker_epic(epic_id)
    data = client.get("/projects/#{config.project_id}/epics/#{epic_id}").body
    TrackerApi::Resources::Epic.new({ project_id: config.project_id }.merge(data))
  end

  def self.start_story(story_id)
    tracker_story = project.story(story_id)
    tracker_story.accepted_at   = nil
    tracker_story.current_state = 'started'
    tracker_story.save
  end

  def self.finish_story(story_id)
    tracker_story = project.story(story_id)
    tracker_story.current_state = tracker_story.story_type == 'chore' ?  'accepted' : 'finished'
    tracker_story.save
  end

  def self.project
    client.project(config.project_id)
  end

  def self.client
    TrackerApi::Client.new(token: config.api_token)
  end
end
