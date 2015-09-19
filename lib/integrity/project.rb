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
    property :pushes, Integer, default: 0

    timestamps :at

    default_scope(:default).update(order: [:name.asc])

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
      log("[method:build_complete!] params: #{params.inspect}")
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
        log("[method:build_complete!] Completed build with success: #{success}, code: #{code.inspect}")
        build.complete!(success)
      else
        log("[method:build_complete!] Could not find a build corresponding to payload: #{params.inspect}")
      end
    rescue => e
        log("[method:build_complete!] Rescure error: #{e.message}")
    ensure
      log("[method:build_complete!] ensure -> triggering build:complete")
      Integrity::Event.trigger('build:completed')
    end

    def get_artifacts
      artifacts.split(";")
    end

    def artifacts_empty?
      artifacts.nil? || artifacts.empty?
    end

    def repo
      @repo ||= Integrity::Repository.new(uri, branch)
    end

    def get_branch(commit=nil)
      name = commit if commit.is_a?(String)
      name ||= commit.try(:branch) || 'master'
      branch = (branches.first(name: name) || branches.create(name: name))
      branch.save
      branch
    end

    #This is a temporary solution for psql apps to use the psql spec helper. It would be better if
    #the correct file were checked out of github.
    #
    def choose_service_template(service)
        template = service.presence || 'spec'
        template = project_service_spec_template if template == 'spec'
    end

    #def project_service_spec_template
      #uses_psql? ? 'spec_psql' : 'spec'
    #end

    #def uses_psql?
      #psql_apps = ['banyan']
      #psql_apps.include?(name)
    #end

    def inc_pushes
      self.pushes += 1
    end

    def build(commit, rebuild=false, service=nil)
      if commit.is_a?(Hash)
        commit = commit.merge(project_id: id)
      else
        commit = commit.attributes.except(:id, :build_id, :created_at, :updated_at)
      end

      commit = Hashie::Mash.new(commit)
      branch = get_branch(commit)
      if commit.identifier.present?
        build = builds.create(
          branch: branch,
          #service_template: choose_service_template(service),
          rebuild: rebuild
        )
        commit = commit.merge(build_id: build.id)
        Integrity::Commit.create(commit)

        if build.invalid_sha?
          log("[method:build] Invalid sha for #{commit.inspect} - [Start-complete] invalid_sha")
          build.destroy if build.saved?
          return
        end

        build.save

        build.reload
        if !build.commit
          Integrity.logger.debug "[fml] where is the commit for build id=#{build.id}"
        end

        if !rebuild
          inc_pushes
          save
        end

        build.run
        build
      end
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

    def master_branch
      branches.first(name: 'master')
    end

    def latest_master_build
      _master_branch = master_branch
      _master_branch ? _master_branch.builds.last : nil
    end

    private

    def fix_line_endings
      if (command = self.command).present?
        command = command.gsub("\r\n", "\n").gsub("\r", "\n")
        attribute_set(:command, command)
      end
    end

    def log(msg)
      puts msg
      Integrity.logger.info "[Integrity::Project]:event:#{msg}"
    end
  end
end
