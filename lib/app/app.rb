require 'rubygems'
require 'sinatra'
require 'omniauth'
require 'omniauth-github'
require 'hashie'
require 'app/helpers'
require 'sinatra/base'
require 'rack/flash'
require 'cgi'
require 'i18n'

module Integrity
  class App < Sinatra::Base

    configure do
      enable  :sessions
      enable  :partial_underscores, :logging, :methodoverride, :static
      disable :build_all

      set :root, File.dirname(__FILE__)
      set :partial_template_engine, :erb
      set :session_secret, 'secret'

      I18n.load_path = Dir[File.join(settings.root, 'config', 'locale', '*.yml')]
      I18n.backend.load_translations
    end

    helpers Integrity::Helpers

    def current_user
      Hashie::Mash.new(session[:user])
    end

    def logged_in?
      !!session[:user]
    end

    def authorized_ip?
      remote_ip.index('10.') == 0 || settings.development?
    end

    def web_hook?
      request.path_info.include?('hook')
    end

    def status_update?
      request.path_info.include?('status.json')
    end

    def remote_ip
      request.env['HTTP_X_FORWARDED_FOR'].to_s
    end

    not_found do
      status 404
      show :not_found, title: 'lost, are we?'
    end

    error do
      @error = request.env['sinatra.error']
      status 500
      show :error, title: 'something has gone terribly wrong'
    end

    before do
      halt 403 unless authorized_ip? || web_hook? || status_update?
      halt 404 if request.path_info.include?('favico')

      if Integrity.config.base_url.present?
        Integrity.configure {|c| c.base_url = url_for('/', :full) }
      end
    end

    before '/secure/*' do
      unless logged_in?
        session[:previous_url] = request.path
        @error = 'Sorry guacamole, you need to be logged in to visit ' + request.path
        halt erb(:login_form)
      end
    end

    post '/status.json', provides: :json do
      params.symbolize_keys!
      @format = :json
      STDERR.puts "PARAMS:  #{params.inspect}"

      current_project.build_complete!(params.slice(:success, :sha, :build_id))
      json current_project
    end

    post '/hook.json', provides: :json do
      @format = :json
      STDERR.puts "PARAMS:  #{params.inspect}"

      build = Payload.build(params, build_all?)
      json build
    end

    get '/login' do
      login_required
      redirect root_url.to_s
    end

    get '/logout' do
      session.delete(:user)
      erb "<div class='alert alert-message'>Logged out</div>"
    end

    get '/auth/github/callback' do
      auth_profile
      redirect to where_user_came_from
    end

    post '/:project/hook' do |token|
      pass unless github_enabled?
      Payload.build(params[:payload], build_all?).to_s
    end

    post '/github/:token' do |token|
      pass unless github_enabled?
      halt 403 unless token == github_token
      Payload.build(params, build_all?).to_s
    end

    ## Project RESTful Endpoints
    ##########################

    # New Project (Form)
    get '/new' do
      login_required

      @project = Project.new
      show :new, title: ['projects', 'new project']
    end

    # List Projects (Index)
    ['/?', '/projects'].each do |path|
      get path, provides: 'html' do
        load_projects
        @masters = Integrity::Branch.all(name: 'master')
        @builds  = Integrity::Build.all(order: :created_at.desc)
        show :home, title: 'projects'
      end
    end

    # Get Project (Show)
    get '/:project' do
      login_required unless current_project.public?

      if limit = Integrity.config.project_default_build_count
        @builds = current_project.sorted_builds.all(limit: limit + 1)
        if @builds.length <= limit
          @showing_all_builds = true
        else
          # we fetched one build more than needed
          @builds.pop
        end
      else
        @builds = current_project.sorted_builds
        @showing_all_builds = true
      end

      @status = current_project.status
      @branches = current_project.branches(order: [:name.asc, :created_at.desc])

      show :project, title: ['projects', current_project.name]
    end

    # Create Project
    post '/?' do
      login_required

      Integrity.logger.info "PARAMS:\n#{params.inspect}"
      @project = Project.new(params[:project_data])

      if @project.save
        update_notifiers_of(@project)
        redirect project_url(@project).to_s
      else
        show :new, title: ['projects', 'new project']
      end
    end

    # Fetch Projects List As JSON
    ['/?', "/projects\.json"].each do |path|
      get path, provides: 'json' do
        @format = :json
        load_projects
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
      login_required unless current_project.public?
      
      json current_project
    end

    # Edit Project (Form)
    get '/:project/edit' do
      login_required
      show :edit, title: ['projects', current_project.permalink, 'edit']
    end

    # Update Project
    put '/:project' do
      login_required

      if current_project.update(params[:project_data])
        update_notifiers_of(current_project)
        redirect project_url(current_project).to_s
      else
        show :new, title: ['projects', current_project.permalink, 'edit']
      end
    end

    # Delete Project
    delete '/:project' do
      login_required

      current_project.destroy
      redirect root_url.to_s
    end

    # Get Project (List ALL Builds)
    get '/:project/all' do
      login_required unless current_project.public?

      @builds = current_project.sorted_builds
      @showing_all_builds = true
      @branches = current_project.branches(order: [:name.asc, :created_at.desc])

      show :project, title: ['projects', current_project.name]
    end

    # Ping Project (Check if Project Exists)
    get '/:project/ping' do
      login_required unless current_project.public?

      if current_project.status != :success
        halt 412, current_project.status.to_s
      else
        current_project.last_build.sha1
      end
    end

    # Get Project Status Icon
    get "/:project\.png" do
      login_required unless current_project.public? || Integrity.config.status_image_always_public?

      send_file File.join(File.dirname(__FILE__), 'public', 'status', current_project.status.to_s + '.png')
    end

    ## Build RESTful Endpoints
    ##########################

    # Create Build From Head
    post '/:project/builds' do
      login_required

      @build = current_project.build_head
      redirect build_url(@build).to_s
    end

    # Create Build From Commit (Re-build)
    post '/:project/builds/:build' do
      login_required

      @build = current_project.build(current_build.commit)
      redirect build_url(@build).to_s
    end

    # Show Build (Read)
    get '/:project/builds/:build' do
      login_required unless current_project.public?

      @status = current_build.status
      show :build, title: ['projects', current_project.permalink,
        current_build.sha1_short]
    end

    # Delete Build
    delete '/:project/builds/:build' do
      login_required

      url = project_url(current_build.project).to_s
      current_build.destroy!
      redirect url
    end

    # Stop Running Build From Commit (Re-build)
    post '/:project/builds/:build/destroy' do
      login_required

      if current_build.in_progress?
        Integrity::Builder.destroy_build(current_build)
        current_build.update(state: 'killed', completed_at: Time.now)
      end

      redirect project_url(current_project).to_s
    end

    # Get Raw Build Output
    get '/:project/builds/:build/raw' do
      login_required unless current_project.public?

      content_type :text
      current_build.output
    end

    # Send Build notification
    get '/:project/builds/:build/notify' do
      login_required unless current_project.public?
      current_build.notify
      redirect build_url(current_build).to_s
    end

    # Get Build Artifact
    get '/:project/builds/:build/artifacts/:artifact' do |project, build, artifact|
      login_required unless current_project.public?

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
