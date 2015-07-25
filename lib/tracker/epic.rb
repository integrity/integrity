require 'erb'
require 'i18n'

module Tracker
  class Epic
    include DataMapper::Resource

    property :id,            Serial
    property :name,          Text, :lazy => false
    property :label_id,      Integer, :lazy => false

    timestamps :at

    has n, :stories

    def self.create(tracker_epic_id, tracker_epic = nil)
      unless tracker_epic
        tracker_epic = TrackerWrapper.tracker_epic(tracker_epic_id)
      end
      return unless tracker_epic

      epic = Epic.new
      epic.id = tracker_epic.id
      epic.name = tracker_epic.name
      epic.label_id = tracker_epic.foobar
      epic.save
    end

    def self.create_from_hook(params)
      epic = Epic.new
      epic.id = params[:id]
      epic.name = params[:name]
      epic.label_id = params[:label_id]
      epic.save
    end

    def self.update_from_hook(params)
      epic = Epic.first_or_create(id: params[:id])
      epic.name  = params[:name]
      epic.save
    end

  end
end
