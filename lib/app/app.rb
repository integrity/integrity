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
require 'sinatra/static_assets'

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
      set :slim, layout_engine: :erb, layout: :layout

      I18n.load_path += Dir[File.join(settings.root, 'config', 'locale', '*.yml')]
      I18n.backend.load_translations
    end

    helpers Integrity::Helpers

    def log(msg)
      user = current_user ? "{user: #{current_user.username}}" : ""
      Integrity.logger.debug "[Integrity::App]: #{msg} user:#{user}"
    end

    def current_user
      Hashie::Mash.new(session[:user])
    end

    def logged_in?
      !!session[:user]
    end

    def authorized_ip?
      remote_ip.index('10.') == 0 || Integrity.development?
    end

    def web_hook?
      ['hook', 'tracker'].any? { |w| request.path_info =~ /#{w}/}
    end

    def status_update?
      request.path_info.include?('status.json')
    end

    def remote_ip
      request.env['HTTP_X_FORWARDED_FOR'].to_s
    end

    def restart_pancakes_stacks_after_github_push(push_event_hash)
      branches = Pancakes.branch_info_from_push_event(push_event_hash)
      stacks_to_update = Pancakes::Stack.with_branches(branches)
      stacks_to_update.each do |stack|
        logger.info "restarting stack #{stack.name} after github PushEvent for branches #{branches.inspect}"
        Delayed::Job.enqueue(Pancakes::RestartWithBranchHeadsJob.new(stack.id))
      end
    end

    # each line of this file should contain a substring to match against a branch.
    # if the line starts with a bang, it means 'dont ignore', otherwise if the branch
    # contains the line, it will be ignored. a blank line ignore everything. like a gitignore.
    def ignore_branch?(branch)
      fname = '/tmp/honesty-ignore.txt'
      return false unless File.exists?(fname)
      return !!File.readlines(fname).map{|l| [!l['!'], l.sub('!', '').chomp] } # [negated, line]
        .select{ |line| branch.include?(line[1]) }                             # ignore non-matching lines
        .map(&:first)                                                          # only care about whether the match is positive or negative
        .last                                                                  # only the last positive/negative matters
    end

    not_found do
      Integrity.logger.info "404 in not_found block"
      status 404
      show :not_found, title: '404'
    end

    error do
      @error = request.env['sinatra.error']
      log "error: #{@error.inspect}"
      status 500
      show :error, title: 'something has gone terribly wrong'
    end

    before do
      halt 403 unless authorized_ip? || web_hook? || status_update?
      halt 404 if request.path_info.include?('favico')
      @load_utilization = LoadUtilization.current
      @usage = []
    end

    before '/secure/*' do
      unless logged_in?
        session[:previous_url] = request.path
        @error = 'Sorry guacamole, you need to be logged in to visit ' + request.path
        halt erb(:login_form)
      end
    end

    get '/status', provides: :json do
      json({ 'gitsha' => (`git rev-parse HEAD`).chomp })
    end

    post '/status.json', provides: :json do
      params.symbolize_keys!
      @format = :json
      Integrity.logger.info "[Build:#{params[:build_id]}][fi] POST /status.json - completing current project with params #{params.slice(:success, :sha, :build_id)} Project is #{current_project.inspect}"
      current_project.build_complete!(params.slice(:success, :sha, :build_id))
      json current_project
    end

    post '/hook.json', provides: :json do
      @format = :json
      #log "[HOOK][RECEIVED_GITHUB_PAYLOAD] /hook.json params: #{JSON.dump(params)}"
      #Integrity.logger.debug "[HOOK][RECEIVED_GITHUB_PAYLOAD] /hook.json params: #{JSON.dump(params)}"
      Integrity.logger.debug "[HOOK][RECEIVED_GITHUB_PAYLOAD] /hook.json"
      payload = Payload.new(params)

      if payload.is_new_pull_request?
        pull_request = payload.pull_request
        Integrity.logger.debug "[GITHUB_TRACKER_EVENT] PULL REQUEST FOR TRACKER STORY: #{pull_request[:story_id]}"
        if story = Tracker::Story.first(id: pull_request[:story_id])
          story.pr_url = pull_request[:pr_url]
          story.finish
        end
        halt 200
      end

      halt 200 if ignore_branch?(payload.branch_name)

      if !payload.project
        log "[HOOK] /hook.json params: #{params.inspect} hook.json called without project"
        halt 404
      end

      if payload.deleted?
        log "[HOOK] /hook.json Received branch delete notice for: #{payload.branch_name}"
        if branch = payload.branch
          log "[HOOK] /hook.json Found matching branch. DELETING BRANCH: [#{branch.id}] (#{branch.inspect})"
          branch.destroy
          json branch and return
        end
      end

      if !payload.commit
        log "[HOOK] /hook.json params: #{params.inspect} hook.json called without commit"
        halt 404
      end

      if payload.merge_to_master?
        Integrity.logger.debug "[GITHUB_TRACKER_EVENT] MERGE TO MASTER FOR TRACKER STORY: #{payload.merged_story}"
        if story = Tracker::Story.first(id: payload.merged_story)
          story.deliver
        end
      end

      build = payload.build!
      log "[HOOK] /hook.json Build: #{build.inspect}"
      #restart_pancakes_stacks_after_github_push(params)
      json build
    end

    post '/tracker.json', provides: :json do
      params.symbolize_keys!
      @format = :json

      #Integrity.logger.debug "[HOOK][RECEIVED_TRACKER_PAYLOAD] /tracker.json params: #{JSON.dump(params)}"
      Integrity.logger.debug "[HOOK][RECEIVED_TRACKER_PAYLOAD] /tracker.json"

      params[:primary_resources].each do |primary_resource|
        case params[:highlight]
        when 'started'
          if story = Tracker::Story.get(primary_resource[:id])
            story.set_state(params[:highlight])
          else
            story = Tracker::Story.create(primary_resource[:id])
            story.send_start_email(params[:performed_by][:name])
          end
        when 'finished', 'delivered', 'accepted', 'unstarted'
          if story = Tracker::Story.first(id: primary_resource[:id])
            story.set_state(params[:highlight])
          end
        when 'edited'
          if params[:changes].first[:kind] == 'epic'
            Tracker::Epic.update_from_hook params[:primary_resources].first
          end
# params: {"kind":"story_update_activity","guid":"422567_141430","project_version":141430,"message":"Ken Berland edited this feature","highlight":"edited","changes":[{"kind":"label","change_type":"update","id":12316046,"original_values":{"counts":{"number_of_zero_point_stories_by_state":{"accepted":0,"started":1,"finished":0,"unstarted":0,"planned":0,"delivered":0,"unscheduled":0,"rejected":0,"kind":"counts_by_story_state"},"sum_of_story_estimates_by_state":{"accepted":0,"started":0,"finished":0,"unstarted":0,"planned":0,"delivered":0,"unscheduled":0,"rejected":0,"kind":"counts_by_story_state"},"number_of_stories_by_state":{"accepted":0,"started":1,"finished":0,"unstarted":0,"planned":0,"delivered":0,"unscheduled":0,"rejected":0,"kind":"counts_by_story_state"},"kind":"story_counts"}},"new_values":{"counts":{"number_of_zero_point_stories_by_state":{"accepted":0,"started":0,"finished":0,"unstarted":0,"planned":0,"delivered":0,"unscheduled":0,"rejected":0,"kind":"counts_by_story_state"},"sum_of_story_estimates_by_state":{"accepted":0,"started":0,"finished":0,"unstarted":0,"planned":0,"delivered":0,"unscheduled":0,"rejected":0,"kind":"counts_by_story_state"},"number_of_stories_by_state":{"accepted":0,"started":0,"finished":0,"unstarted":0,"planned":0,"delivered":0,"unscheduled":0,"rejected":0,"kind":"counts_by_story_state"},"kind":"story_counts"}},"name":"baz"},{"kind":"story","change_type":"update","id":99846558,"original_values":{"label_ids":[12316046,12315958,12266016],"updated_at":1437842544000,"labels":["baz","foo","honesty 3"]},"new_values":{"label_ids":[12315958,12266016],"updated_at":1437842562000,"labels":["foo","honesty 3"]},"name":"Update epics when stories are updated","story_type":"feature"}],"primary_resources":[{"kind":"story","id":99846558,"name":"Update epics when stories are updated","story_type":"feature","url":"https://www.pivotaltracker.com/story/show/99846558"}],"project":{"kind":"project","id":422567,"name":"Grand Rounds"},"performed_by": :{"kind":"person","id":998335,"name":"Ken Berland","initials":"KB"},"occurred_at":1437842562000}
          if params[:kind] == 'story_update_activity'
            id = params[:primary_resources].first[:id]
            params[:changes].each do |c|
              Tracker::Story.update_from_hook(id, c['new_values'])
            end
          end
        when 'added'
          if params[:changes].first[:kind] == 'epic'
            Tracker::Epic.create_from_hook params[:primary_resources].first.merge({ label_id: params[:changes].first[:new_values][:label_id] })
          end
        when 'deleted'
          if story = Tracker::Story.first(id: primary_resource[:id])
            story.destroy!
          end
        else
        end
      end

      'Post Successful'
    end


    ######
    #     #    ##    #    #   ####     ##    #    #  ######   ####
    #     #   #  #   ##   #  #    #   #  #   #   #   #       #
    ######   #    #  # #  #  #       #    #  ####    #####    ####
    #        ######  #  # #  #       ######  #  #    #            #
    #        #    #  #   ##  #    #  #    #  #   #   #       #    #
    #        #    #  #    #   ####   #    #  #    #  ######   ####
    ###############################################################

    get '/pancakes' do
      @stacks = Pancakes::Stack.order(:created_at)
      slim :"pancakes/stacks/index"
    end

    get '/pancakes/stacks/:id' do
      @stack = Pancakes::Stack[params[:id]]

      if @stack
        slim :"pancakes/stacks/show"
      else
        redirect to('/pancakes')
      end
    end

    get '/pancakes/stacks/:id/:codebase/toggle_lock' do
      @stack = Pancakes::Stack[params[:id]]

      if @stack
        @commit = @stack.commit_for_codebase(params[:codebase])

        if @commit
          @commit.toggle_lock!
        end
      end

      redirect back
    end

    get '/pancakes/stacks/:id/restart_with_branch_heads' do
      @stack = Pancakes::Stack[params[:id]]

      if @stack
        @stack.update_all(desired_state: (@stack.state == :off ? :running : :off))
        Delayed::Job.enqueue(Pancakes::Background::RestartWithBranchHeadsJob.new(@stack.id))
      end

      redirect back
    end

    get '/pancakes/stacks/:id/restart_with_same_commits' do
      @stack = Pancakes::Stack[params[:id]]

      if @stack
        @stack.update_all(desired_state: (@stack.state == :off ? :running : :off))
        Delayed::Job.enqueue(Pancakes::Background::RestartWithSameCommitsJob.new(@stack.id))
      end

      redirect back
    end

    get '/pancakes/stacks/:id/bring_down' do
      @stack = Pancakes::Stack[params[:id]]

      if @stack
        Delayed::Job.enqueue(Pancakes::Background::BringDownJob.new(@stack.id))
      end

      redirect back
    end

    get '/pancakes/stacks/:id/refresh' do
      @stack = Pancakes::Stack[params[:id]]

      if @stack
        @stack.state_from_cluster!
      end

      redirect back
    end

    get '/pancakes/stacks/:id/destroy' do
      @stack = Pancakes::Stack[params[:id]]
      @stack.state_from_cluster! if @stack

      if @stack && @stack.state == :off
        @stack.destroy
      #elsif @stack.state != :off
        #flash[:error] = "bring down the stack before deleting"
      #else
        #flash[:error] = "stack not found"
      end
      redirect back
    end

    post '/pancakes/stacks' do
      services = Pancakes::Services.full_services

      @stack = Pancakes::Stack.create_with_git_strings(
        services:       services,
        pocs:           params[:pocs],
        branches:       params[:branches],
        desired_state: :running,
      )

      #flash[:notice] = "Stack created with sha #{@stack.short_sha}. Click 'Refresh state' to refresh the state, if you want."
      Delayed::Job.enqueue(Pancakes::Background::BringUpJob.new(@stack.id))

      redirect back
    end

    get '/pancakes/branches/:codebase.json' do |codebase|
      term = params[:term]

      if term
        branches = Octokit.branches(Pancakes.repo_name(codebase)).map{|branch| branch[:name] }
        # put master at the top of the list
        if branches.delete('master')
          branches.sort!
          branches.unshift('master')
        end
        branches = branches.select do |name|
          !!name[term]
        end
      else
        branches = []
      end

      JSON.dump(branches)
    end

    #get '/pancakes/api/vX/stacks/search' do
      #branches = params[:branches]
      #data = params[:data]
      #service_name = params[:service_name]
      #update_state = params[:update_state]

      #@stack = Pancakes::Stack.first_with_branches(branches)

      #if !@stack
        #logger.info 'stack not found'
        #halt 400, "stack not found\n"
      #else
        #logger.info "stack found: #{@stack.sha}"

        #if update_state == 'true'
          #@stack.state_from_cluster!
        #end

        #@unit = @stack.unit_with_service_name(service_name)

        #if !@unit
          #logger.info 'unit not found'
          #halt 400, "unit not found\n"
        #elsif data == 'tcp_info'
          #tcp_string = @unit.tcp_str
          #if tcp_string.empty?
            #logger.info 'tcp_string not found. service may not be running.'
            #halt 400, "tcp_string not found. service may not be running.\n"
          #else
            #tcp_string
          #end
        #else
          #halt 500, 'something was wrong'
        #end
      #end
    #end

    post '/pancakes/api/vX/stacks' do
      if !params[:dry_run]
        services = (params[:branches][:tp] && params[:branches][:tp].empty?) ? Pancakes::Services.jarvis_services : Pancakes::Services.tp_services
        services = (params[:branches][:banyan] && params[:branches][:banyan].empty?) ? Pancakes::Services.jarvis_services : Pancakes::Services.banyan_services
        @stack = Pancakes::Stack.create_with_git_strings(
          services:       services,
          pocs:           params[:pocs],
          branches:       params[:branches],
          desired_state: :running,
        )

        @stack.save
        Delayed::Job.enqueue(Pancakes::Background::BringUpJob.new(@stack.id))

        response['Pancakes-Stack-Id'] = @stack.id.to_s
        response['Pancakes-Stack-SHA'] = @stack.sha
        response['Pancakes-Stack-State-Path'] = "/pancakes/api/vX/stacks/#{@stack.id}/state"
        response['Pancakes-Stack-BringDown-Path'] = "/pancakes/api/vX/stacks/#{@stack.id}/bring_down"

        halt 200
      else
        id = '42'
        response['Pancakes-Stack-Id'] = id
        response['Pancakes-Stack-SHA'] = 'beeff00d'
        response['Pancakes-Stack-State-Path'] = "/pancakes/api/vX/stacks/#{id}/state"
        response['Pancakes-Stack-BringDown-Path'] = "/pancakes/api/vX/stacks/#{id}/bring_down"
        halt 200, id
      end
    end

    delete '/pancakes/api/vX/stacks/:id/bring_down' do
      halt 200 if params[:dry_run]

      @stack = Pancakes::Stack[params[:id]]

      if @stack
        Delayed::Job.enqueue(Pancakes::Background::BringDownJob.new(@stack.id, destroy: true))
        halt 200
      else
        halt 400, "stack(#{params[:id]}) could not be found for destroy\n"
      end
    end

    get '/pancakes/api/vX/stacks/:id/tcp_info' do
      halt 200, '1.2.3.4:5678' if params[:dry_run]

      @stack = Pancakes::Stack[params[:id]]
      update_state = params[:update_state]
      service_name = params[:service_name]

      if !@stack
        logger.info 'stack not found'
        halt 400, "stack not found\n"
      end

      logger.info "stack found id=#{@stack.id}"

      if update_state == 'true'
        @stack.state_from_cluster!
      end

      @unit = @stack.unit_with_service_name(service_name)

      if @unit
        tcp_string = @unit.tcp_str
        if !tcp_string
          logger.info 'tcp_string not found. service may not be running.'
          halt 400, "tcp_string not found. service may not be running.\n"
        else
          halt 200, tcp_string
        end
      else
        logger.info 'unit not found'
        halt 400, "unit not found\n"
      end
    end

    get '/pancakes/api/vX/stacks/:id/addrs.json' do
      logger.info "looking for stack with id=#{params[:id]}"
      @stack = Pancakes::Stack[params[:id]]
      #@stack.state_from_cluster!

      if @stack
        logger.info "stack found id=#{@stack.id}"

        if @stack.service_addrs
          sa = @stack.service_addrs
          raise "service_addrs is empty" if sa.empty?
          sa = JSON.dump(sa)
          logger.info "service_addr JSON='#{sa}'"
          halt 200, sa
        else
          logger.info "stack service_addrs NOT found id=#{@stack.id}"
          halt 400, "not found: service_addrs for stack id=#{params[:id]}\n"
        end
      else
        logger.info "stack NOT found id=#{@stack.id}"
        halt 400, "not found: stack id=#{params[:id]}\n"
       end
    end

    get '/pancakes/api/vX/stacks/:id/state' do
      halt 200, 'running' if params[:dry_run]

      @stack = Pancakes::Stack[params[:id]]
      @stack.state_from_cluster!

      if @stack
        halt 200, "#{@stack.state}"
      else
        halt 400, "stack(#{params[:id]}) could not be found\n"
      end
    end

    # end pancakes
    ###############################################################

    get '/utilization.json' do
      json Integrity.instance_manager.utilization_metrics
    end

    get '/coreos/key' do
      halt Integrity.private_key
    end

    get '/login' do
      login_required
      redirect root_url
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
      login_required
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
      login_required
      redirect '/settings'
    end

    get '/jobs' do
      show :jobs, title: 'jobs'
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
        @masters = Integrity::Branch.all(name: 'master').sort{|a,b| b.project.pushes <=> a.project.pushes }
        @builds  = Integrity::Build.all(limit: 30, order: :created_at.desc)
        @pending = @builds.pending.all(order: :created_at.desc)
        @running = @builds.running.all(order: :started_at.desc)
        @completed = @builds.completed.all(order: :completed_at.desc)
        @stories_in_flight = Tracker::Story.all(:current_state => ['started', 'finished'], :order => :created_at.asc)
        show :home, title: 'project'
      end
    end

    ['/epics', '/allocations'].each do |path|
      get path do
        login_required
        @report = Tracker::Report.developer_report
        slim :epics, layout: path.eql?('/epics') ? :tv_layout : :layout
      end
    end

    get '/delivered' do
      login_required
      @delivered_stories = Tracker::Story.all(:current_state => ['delivered'], :order => :created_at.asc)
      slim :delivered
    end

    # List Running Builds (Index)
    get '/running' do
      login_required

      @builds = Integrity::Build.running
      show :running, title: 'running builds'
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
      @branches = current_project.branches(order: [:name.asc, :created_at.desc]).first(8)

      show :project, title: ['projects', current_project.name]
    end

    # Create Project
    post '/?' do
      login_required

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
        redirect project_url(current_project)
      else
        show :new, title: ['projects', current_project.permalink, 'edit']
      end
    end

    # Delete Project
    delete '/:project' do
      login_required

      current_project.destroy
      redirect root_url
    end

    # Get Project (List ALL Builds)
    get '/:project/all' do
      login_required unless current_project.public?

      @builds = current_project.sorted_builds
      @showing_all_builds = true
      @branches = []

      show :project, title: ['projects', current_project.name]
    end

    get '/:project/:branch' do
      login_required unless current_project.public?

      if limit = Integrity.config.project_default_build_count
        @builds = current_branch.sorted_builds.all(limit: limit + 1)
        if @builds.length <= limit
          @showing_all_builds = true
        else
          # we fetched one build more than needed
          @builds.pop
        end
      else
        @builds = current_branch.sorted_builds
        @showing_all_builds = true
      end

      @latest_builds = @showing_all_builds ? @builds.all(limit: 12) : @builds.all(limit: 4)

      show :branch, title: ['branches', current_branch.name]
    end



    # Get Project (List ALL Builds)
    get '/:project/:branch/all' do
      login_required unless current_project.public?

      @builds = current_branch.sorted_builds
      @latest_builds = @builds.all(limit: 4)
      @showing_all_builds = true

      show :branch, title: ['branches', current_branch.name]
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

    # Create Build From Commit (Re-build)
    post '/:project/builds/:build' do
      login_required

      log("[Build:#{current_build.id}] /:project/builds/:build (Build:Re-build) build:#{current_build.inspect}, commit: #{current_build.commit.inspect}")
      @build = current_project.build(current_build.commit, true, params["template"])
      redirect build_url(@build)
    end

    # Show Build (Read)
    get '/:project/builds/:build' do
      login_required unless current_project.public?

      @status = current_build.status
      show :build, title: ['projects', current_project.permalink, current_build.sha1_short]
    end

    # Delete Build
    delete '/:project/builds/:build' do
      log("[Build:#{current_build.id}] DELETE /:project/builds/:build (Delete build) build:#{current_build.inspect}")
      login_required
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
      login_required
      current_build.cancel_with_reason("user #{current_user.name}", 'manual kill', 'POST /:project/builds/:build/cancel')
      redirect build_url(current_build)
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
      redirect build_url(current_build)
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
