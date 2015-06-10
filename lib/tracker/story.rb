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

    def finish
      self.commit_state = 'finished'
      TrackerWrapper.finish_story(id)
    end
  end
end
