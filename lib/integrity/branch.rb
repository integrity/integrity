module Integrity
  class Branch
    include DataMapper::Resource
    include Integrity::WebUtils

    property :id,            Serial
    property :project_id,    Integer, required: true
    property :name,          String,  required: true, length: 255
    property :permalink,     String,  length: 255
    property :last_build_id, Integer, required: false
    property :story_id,      Integer, required: false
    timestamps :at

    has n, :builds
    belongs_to :project
    belongs_to :last_build, 'Build'
    belongs_to :story, 'Tracker::Story'

    before :save, :set_permalink
    before :save, :set_story

    before :destroy do
      builds.destroy!
    end

    delegate :repo, to: :project
    delegate :status, :human_status, :human_duration, :successful?, :failed?, :pending?, :building?, to: :last_build, allow_nil: true

    def set_story
      story_id = self.name.scan(/\d{6,}/).last
      return unless story_id

      if Tracker::Story.get(story_id)
        self.story = Tracker::Story.get(story_id)
      else
        self.story = Tracker::Story.create(story_id)
      end
    end

    def blank?
      last_build.nil?
    end

    def sorted_builds
      builds(order: [:created_at.desc, :id.desc])
    end

    def builds_before(build)
      sorted_builds.all(:created_at.lt => build.created_at)
    end

    def most_recent_build
      builds.first(order: :created_at.desc)
    end
  end
end
