module Integrity
  class Branch
    include DataMapper::Resource
    include Integrity::DataUtils

    property :id,         Serial
    property :project_id, Integer, required: true
    property :name,       String,  required: true, length: 255
    property :permalink,  String,  length: 255
    property :last_build_id, Integer, required: false

    timestamps :at

    has n, :builds
    has 1, :diligence_branch
    belongs_to :project
    belongs_to :last_build, 'Build'

    before :save, :set_permalink

    before :destroy do
      builds.destroy!
    end

    def self.master(query = :all)
      scope query, name: 'master'
    end

    def self.not_master(query = :all)
      scope query, :name.not => 'master', order: [:name.asc, :created_at.desc]
    end

    delegate :repo, :uri, to: :project
    delegate :status, :human_status, :human_duration, :successful?, :failed?, :pending?, :building?, to: :last_build, allow_nil: true

  end
end
