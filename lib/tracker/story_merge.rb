module Tracker
  class StoryMerge
    include DataMapper::Resource

    property :id,       Serial
    property :estimate, Integer
    property :nes,      Boolean
    property :type,     String
    property :user_id,  Integer

    timestamps :at

    def self.create(story_id)
      return unless tracker_story = TrackerWrapper.tracker_story(story_id)

      story_merge = StoryMerge.first(id: story_id) || StoryMerge.new

      story_merge.id       = tracker_story.id
      story_merge.estimate = tracker_story.estimate.to_i
      story_merge.nes      = tracker_story[:labels].any?{|label| label.name.eql?('nes')}
      story_merge.type     = tracker_story.story_type
      story_merge.user_id  = tracker_story.owned_by_id

      story_merge.save
    end
  end
end
