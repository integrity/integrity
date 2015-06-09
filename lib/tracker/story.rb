module Tracker
  class Story < Sequel::Model
    include DataMapper::Resource

    set_dataset :tracker_stories
    plugin :timestamps

    property :id,            Serial
    property :url,           String
    property :project_id,    Integer
    property :name,          Text, :lazy => false
    property :type,          String
    property :current_state, String
    property :commit_state,  String

    has n, :branches, 'Integrity::Branch'
    has n, :users, :through => Resource

    def self.create(tracker_story)
      story = Story.new
      story.id            = tracker_story.id
      story.url           = tracker_story.url
      story.project_id    = tracker_story.project_id
      story.name          = tracker_story.name
      story.type          = tracker_story.story_type
      story.current_state = tracker_story.current_state
      story.save
      story
    end
  end
end
