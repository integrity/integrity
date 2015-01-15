module Integrity
  class Branch
    include DataMapper::Resource
    include Integrity::WebUtils

    property :id,         Serial
    property :project_id, Integer, required: true
    property :name,       String,  required: true, length: 255
    property :permalink,  String,  length: 255
    property :last_build_id, Integer, required: false

    timestamps :at

    has n, :builds
    has 1, :branch_builder
    belongs_to :project
    belongs_to :last_build, 'Build'

    before :save, :set_permalink

    before :destroy do
      builds.destroy!
    end

    delegate :repo, to: :project
    delegate :status, :human_status, :human_duration, :successful?, :failed?, :pending?, :building?, to: :last_build, allow_nil: true

    def blank?
      last_build.nil?
    end

    def sorted_builds
      builds(order: [:created_at.desc, :id.desc])
    end

  end
end
