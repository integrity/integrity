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

  def self.set_state(story_id, state)
    tracker_story = project.story(story_id)
    tracker_story.accepted_at   = nil
    tracker_story.current_state = state
    tracker_story.save
  end

  def self.add_comment(story_id, comment)
    client.post("projects/#{config.project_id}/stories/#{story_id}/comments", {body: {text: comment}})
  end

  def self.project
    client.project(config.project_id)
  end

  def self.client
    TrackerApi::Client.new(token: config.api_token)
  end

  def self.top_nes_story
    data = client.get("/projects/#{config.project_id}/iterations?scope=backlog").body.first
    return unless story = data['stories'].find{|story| story['labels'].select{|label| label['name'] == 'nes'}.any? }
    {
      story_id: story['id'],
      name:     story['name'],
      url:      story['url'],
    }
  end
end
