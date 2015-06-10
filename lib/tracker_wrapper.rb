class TrackerWrapper
  PivotalTracker::Client.token = ENV['PIVOTAL_TRACKER_TOKEN']
  PivotalTracker::Client.timeout = 50
  @project = PivotalTracker::Project.find(ENV['PIVOTAL_TRACKER_PROJECT_ID'])

  def self.tracker_story(story_id)
    @project.stories.find(story_id)
  end

  def self.finish_story(story_id)
    tracker_story = @project.stories.find(story_id)
    tracker_story.story_type == 'chore' ? tracker_story.update({current_state: 'accepted'}) : tracker_story.update({current_state: 'finished'})
  end
end
