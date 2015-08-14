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

      report = Report.new

      report.id       = tracker_story.id
      report.estimate = tracker_story.estimate.to_i
      report.nes      = tracker_story[:labels].any?{|label| label.name.eql?('nes')}
      report.type     = tracker_story.story_type
      report.user_id  = tracker_story.owned_by_id

      report.save
    end
  end
end
