require 'integrity/project/notifiers'

module Integrity
  class Project
    include DataMapper::Resource
    include Integrity::WebUtils
    include Notifiers

    property :id,         Serial
    property :name,       String,  required: true,  length: 255,  unique: true
    property :permalink,  String,  length: 255
    property :uri,        URI,     required: true,  length: 255
    property :branch,     String,  required: true,  length: 255,  default: 'master'
    property :command,    String,  required: true,  length: 2000, default: 'rake'
    property :artifacts,  String,  required: false, length: 1000
    property :public,     Boolean, default: true
    property :last_build_id, Integer, required: false
    property :weight, Integer, required: true, default: 1

    timestamps :at

    default_scope(:default).update(:order => [:name.asc])

    has n, :builds
    has n, :branches
    has n, :commits
    has n, :notifiers
    belongs_to :last_build, 'Build'

    before :save, :set_permalink
    before :save, :fix_line_endings

    after :create do
      notifiers.first_or_create(name: 'Github', enabled: true, config: {action: 'push'})
    end

    before :destroy do
      builds.destroy!
      branches.destroy!
    end

    delegate :status, :human_status, :human_duration, :successful?, :failed?, :pending?, :building?, to: :last_build, allow_nil: true
    delegate :owner, to: :repo

    def build_complete!( params )
      code = params[:success]
      sha = params[:sha]
      build_id = params[:build_id]

      if build_id
        build = Build.first(id: build_id)
      elsif sha
        commit = Commit.last(project_id: id, :identifier.like => "#{sha}%")
        build = commit.try(:build)
      else
        raise ArgumentError, 'Requires sha or build id'
      end

      if build
        success = code.present? && code.zero?
        build.complete!(success)
        Builder.queue_builds!
      else
        raise ArgumentError, 'Could not find a corresponding build'
      end
    end

    def get_artifacts
      artifacts.split(";")
    end

    def artifacts_empty?
      artifacts.nil? || artifacts.empty?
    end

    def repo
      @repo ||= Repository.new(uri, branch)
    end

    def get_branch(commit=nil)
      name = commit if commit.is_a?(String)
      name ||= commit.try(:branch) || 'master'
      branch = (branches.first(name: name) || branches.create(name: name))
      branch.save
      branch
    end

    def build_head
      commit = Commit.new(
        identifier:   'HEAD',
        author:       last_build.try(:author),
        message:      'Rebuilding HEAD',
        committed_at: last_build.try(:commit).try(:committed_at),
        branch:       'master',
        project_id:   id
      )
      build(commit)
    end

    def build(commit)
      commit = Hashie::Mash.new(commit) if commit.is_a?(Hash)
      branch = get_branch(commit)

      commit = {
        identifier:   (commit.try(:identifier)   || 'HEAD'),
        author:       (commit.try(:author)       || 'Last Committer'),
        message:      (commit.try(:message)      || 'REBUILD'),
        committed_at: (commit.try(:committed_at) || Time.now),
        branch:       (commit.try(:branch)       || branch.name),
        project_id:   (commit.try(:project_id)   || id)
      }

      _build = builds.create(commit: commit, branch: branch)
      _build.save
      _build.run
      _build
    end

    def fork(new_branch)
      forked = Project.create(
        name:    "#{name} (#{new_branch})",
        uri:     uri,
        branch:  new_branch,
        command: command,
        public:  public?
      )

      notifiers.each { |notifier|
        forked.notifiers.create(
          name:    notifier.name,
          enabled: notifier.enabled?,
          config:  notifier.config
        )
      }

      forked
    end

    def github?
      uri.to_s.include?('github.com')
    end

    # TODO: lame, there is got to be a better way
    def sorted_builds
      builds(order: [:created_at.desc, :id.desc])
    end

    def blank?
      last_build.nil?
    end

    def attributes_for_json
      {
        name:   name,
        status: status
      }
    end
    
    def to_json
      {project: attributes_for_json}.to_json
    end

    private

    def fix_line_endings
      if (command = self.command).present?
        command = command.gsub("\r\n", "\n").gsub("\r", "\n")
        attribute_set(:command, command)
      end
    end

  end
end
