require 'app/helpers'

module Integrity
  class App < Sinatra::Base
    register Sinatra::StaticAssets

    configure do
      enable  :sessions
      enable  :partial_underscores, :logging, :methodoverride, :static
      disable :build_all

      set :root, File.dirname(__FILE__)
      set :partial_template_engine, :erb
      set :session_secret, 'secret'
      set :environment, ENV['RACK_ENV'] || :production

      I18n.load_path += Dir[File.join(settings.root, 'config', 'locale', '*.yml')]
      I18n.backend.load_translations
    end

    helpers Integrity::Helpers

    not_found do
      status 404
      show :not_found, title: 'lost, are we?'
    end

    error do
      @error = request.env['sinatra.error']
      log "error: #{@error.inspect}"
      status 500
      show :error, title: 'something has gone terribly wrong'
    end

    before do
      login_required
      setup_env
    end

    before '/secure/*' do
      unless logged_in?
        session[:previous_url] = request.path
        @error = 'Sorry guacamole, you need to be logged in to visit ' + request.path
        halt erb(:login_form)
      end
    end

    ['/?', '/projects', "/projects\.json", '/diligence_branches'].each do |path|
      before path do
        load_projects
      end
    end

    post '/status.json', provides: :json do
      params.symbolize_keys!
      @format = :json
      log("[Build:#{params[:build_id]}][fi] POST /status.json - completing current project with params #{params.slice(:success, :sha, :build_id)} Project is #{current_project.inspect}")
      current_project.build_complete!(params.slice(:success, :sha, :build_id))
      json current_project
    end

    post '/hook.json', provides: :json do
      @format = :json
      log "[HOOK][RECEIVED_GITHUB_PAYLOAD] /hook.json params: #{params.inspect}"

      payload = Payload.new(params)

      if payload.deleted?
        log "[HOOK] /hook.json Received branch delete notice for: #{payload.branch_name}"
        if branch = payload.branch
          log "[HOOK] /hook.json Found matching branch. DELETING BRANCH: [#{branch.id}] (#{branch.inspect})"
          branch.destroy
          json branch and return
        end
      end

      if not payload.project
        log "[HOOK] /hook.json params: #{params.inspect} hook.json called without project"
        halt 404
      elsif not payload.commit
        halt 404
        log "[HOOK] /hook.json params: #{params.inspect} hook.json called without commit"
      end

      build = payload.build!

        log "[HOOK] /hook.json Build: #{build.inspect}"

      if diligence_branch = Integrity::DiligenceBranch.first(branch: build.branch)
        diligence_branch.rebuild_environment
      end

      json build
    end

    get '/utilization.json' do
      json Integrity.instance_manager.utilization_metrics
    end

    get '/login' do
      redirect to root_path unless oauth?
      notify error: 'You must login to continue' if auth_redirect?
      show :login, title: 'login', layout: false
    end

    get '/logout' do
      session.delete(:user)
      notify alert: 'Logged out'
      redirect to unauthorized_path
      show :login, title: 'login', layout: false
    end

    get '/auth/github/callback' do
      auth_profile
      redirect to where_user_came_from
    end

    post '/:project/hook' do |token|
      log("/:project/hook'(Received Payload) with token: #{token}")
      pass unless github_enabled?
      Payload.build(params[:payload]).to_s
    end

    post '/github/:token' do |token|
      log("/:github/:token'(Received Payload) with params: #{params} and token #{token}")
      pass unless github_enabled?
      halt 403 unless token == github_token
      Payload.build(params).to_s
    end

    # Settings
    get '/settings' do
      @load_utilization = LoadUtilization.current
      loads = [Integrity::LoadUtilization.first(:created_at.lt => 10.minutes.ago)]
      (1..23).each do |n|
        loads << Integrity::LoadUtilization.first(:created_at.lt => n.hour.ago)
      end
      @usage = loads.compact.map(&:usage)
      show :settings, title: 'settings'
    end

    # Change Settings
    post '/settings' do
      redirect '/settings'
    end

    get '/jobs' do
      show :jobs, title: 'jobs'
    end

    ## Project RESTful Endpoints
    ##########################

    # New Project (Form)
    get '/new' do
      @project = Project.new
      show :new, title: ['projects', 'new project']
    end

    # List Projects (Index)
    ['/?', '/projects'].each do |path|
      get path, provides: 'html' do
        @masters = Integrity::Branch.all(name: 'master')
        @builds  = Integrity::Build.all(limit: 30, order: :created_at.desc)
        @pending = @builds.pending.all(order: :created_at.desc)
        @running = @builds.running.all(order: :started_at.desc)
        @completed = @builds.completed.all(order: :completed_at.desc)
        show :home, title: 'project'
      end
    end

    get '/diligence_branches' do
      @active_diligence_branches = Integrity::DiligenceBranch.all(order: :id.desc, active: true)
      @inactive_diligence_branches = Integrity::DiligenceBranch.all(order: :id.desc, active: false)
      @branches = Integrity::Branch.all(limit:30, order: :last_build_id.desc)
      show :diligence_branches
    end

    get '/diligence_branches/:branch_id/start' do |branch_id|
      diligence_branch = Integrity::DiligenceBranch.first(:branch_id => branch_id)

      unless diligence_branch
        branch = Integrity::Branch.get(branch_id)
        diligence_branch = Integrity::DiligenceBranch.create(branch: branch)
      end

      diligence_branch.start
      redirect back
    end

    get '/diligence_branches/:id/stop' do |id|
      diligence_branch = Integrity::DiligenceBranch.get(id)
      diligence_branch.stop
      redirect back
    end

    get '/diligence_branches/:id/flip_lock' do |id|
      diligence_branch = Integrity::DiligenceBranch.get(id)
      diligence_branch.flip_lock
      redirect back
    end

    # List Honesty Users
    get '/users' do
      @users = Integrity::User.all
      show :users, title: 'Users'
    end

    # List Running Builds (Index)
    get '/running' do
      @builds = Integrity::Build.running
      show :running, title: 'running builds'
    end

    # Get Project (Show)
    get '/:project' do
      load_builds(current_project)
      load_branches
      @status = current_project.status
      @branches = current_project.branches(:name.not => 'master', order: [:name.asc, :created_at.desc]).first(7)
      @branches += current_project.branches(name: 'master')
      show :project, title: ['projects', current_project.name]
    end

    # Get Project (Show) (List ALL Builds)
    get '/:project/all' do
      load_builds(current_project, :all)
      load_branches(:all)
      show :project, title: ['projects', current_project.name]
    end

    # Create Project
    post '/?' do
      log("/? (Create Project) params:#{params.inspect}")
      @project = Project.new(params[:project_data])

      if @project.save
        update_notifiers_of(@project)
        redirect project_url(@project)
      else
        show :new, title: ['projects', 'new project']
      end
    end

    # Fetch Projects List As JSON
    ['/?', "/projects\.json"].each do |path|
      get path, provides: 'json' do
        @format = :json
        projects_json = @projects.map do |project|
          project.attributes_for_json
        end
        wrapped_projects = {projects: projects_json}
        json wrapped_projects
      end
    end

    # Fetch Project As JSON
    get "/:project\.json" do
      @format = :json
      json current_project
    end

    # Edit Project (Form)
    get '/:project/edit' do
      show :edit, title: ['projects', current_project.permalink, 'edit']
    end

    # Update Project
    put '/:project' do
      if current_project.update(params[:project_data])
        update_notifiers_of(current_project)
        redirect project_url(current_project)
      else
        show :new, title: ['projects', current_project.permalink, 'edit']
      end
    end

    # Delete Project
    delete '/:project' do
      current_project.destroy
      redirect root_url
    end

    get '/:project/:branch' do
      load_builds(current_branch)
      show :branch, title: ['branches', current_branch.name]
    end

    # Get Project (List ALL Builds)
    get '/:project/:branch/all' do
      load_builds(@branch, :all)
      show :branch, title: ['branches', current_branch.name]
    end

    # Ping Project (Check if Project Exists)
    get '/:project/ping' do
      if current_project.status != :success
        halt 412, current_project.status.to_s
      else
        current_project.last_build.sha1
      end
    end

    # Get Project Status Icon
    get "/:project\.png" do
      send_file File.join(File.dirname(__FILE__), 'public', 'status', current_project.status.to_s + '.png')
    end

    ## Build RESTful Endpoints
    ##########################

    # Create Build From Commit (Re-build)
    post '/:project/builds/:build' do
      log("[Build:#{current_build.id}] /:project/builds/:build (Build:Re-build) build:#{current_build.inspect}, commit: #{current_build.commit.inspect}")
      @build = current_project.build(current_build.commit, true, params["template"])
      redirect build_url(@build)
    end

    # Show Build (Read)
    get '/:project/builds/:build' do
      @status = current_build.status
      show :build, title: ['projects', current_project.permalink, current_build.sha1_short]
    end

    # Delete Build
    delete '/:project/builds/:build' do
      log("[Build:#{current_build.id}] DELETE /:project/builds/:build (Delete build) build:#{current_build.inspect}")
      current_build.destroy!
      redirect root_url
    end

    # Cancel the Pending or Running Build
    post '/:project/builds/:build/fail_reason' do
      log("[Build:#{current_build.id}] fail_reason /:project/builds/:build/fail_reason (Give reason for failure) params:#{params}")
      current_build.update(fail_category: params["fail_reason"])
      redirect build_url(current_build)
    end

    # Cancel the Pending or Running Build
    post '/:project/builds/:build/cancel' do
      current_build.cancel_with_reason("user #{current_user.name}", 'manual kill', 'POST /:project/builds/:build/cancel')
      redirect build_url(current_build)
    end

    # Get Raw Build Output
    get '/:project/builds/:build/raw' do
      content_type :text
      current_build.output
    end

    # Send Build notification
    get '/:project/builds/:build/notify' do
      current_build.notify
      redirect build_url(current_build)
    end

    # Get Build Artifact
    get '/:project/builds/:build/artifacts/:artifact' do |project, build, artifact|
      artifact = CGI.unescape(artifact)
      artifact_files = current_build.artifact_files
      file = artifact_files.detect do |file|
        file[:relative_path] == artifact
      end

      if file.nil?
        halt 404
      end

      fs_path = current_build.build_directory.join(file[:relative_path])
      unless File.exist?(fs_path)
        halt 404
      end

      send_file fs_path, filename: file[:name]
    end

  end

end
