require "app/helpers"

module Integrity
  class App < Sinatra::Base
    set     :root, File.dirname(__FILE__)
    enable  :methodoverride, :static
    disable :build_all

    helpers Integrity::Helpers

    not_found do
      status 404
      show :not_found, :title => "lost, are we?"
    end

    error do
      @error = request.env["sinatra.error"]
      status 500
      show :error, :title => "something has gone terribly wrong"
    end

    before do
      halt 404 if request.path_info.include?("favico")

      unless Integrity.config.base_url
        Integrity.configure { |c| c.base_url = url_for("/", :full) }
      end
    end

    post "/github/:token" do |token|
      unless Integrity.config.github_enabled?
        pass
      end

      unless token == Integrity.config.github_token
        halt 403
      end

      Payload.build(
        JSON.parse(params[:payload]),
        Integrity.config.build_all?
      ).to_s
    end

    get "/?" do
      @projects = authorized? ? Project.all : Project.all(:public => true)

      # we may have no projects defined yet
      @status = :blank
      # statuses can be thought of as having the following hierarchy:
      # success -> pending -> building -> failed
      # status of Integrity overall is the rightmost status of
      # any of displayed projects.
      # statuses are listed in lib/integrity/build.rb.
      @projects.each do |project|
        if project.status == :blank
          # project with no builds.
          # do not change overall status
          next
        end

        case @status
        when :blank
          # first project's status unconditionally sets overall status
          @status = project.status
        when :success
          # any status takes precedence over success
          if project.status != :success
            @status = project.status
          end
        when :pending
          # building and failed take precedence over pending
          if project.status != :success && project.status != :pending
            @status = project.status
          end
        when :building
          # failed takes precedence over building
          if project.status == :failed
            @status = :failed
          end
        else
          # overall status is failed, don't change it
          break
        end
      end

      show :home, :title => "projects"
    end

    get "/login" do
      login_required

      redirect root_url.to_s
    end

    get "/new" do
      login_required

      @project = Project.new
      show :new, :title => ["projects", "new project"]
    end

    post "/?" do
      login_required

      @project = Project.new(params[:project_data])

      if @project.save
        update_notifiers_of(@project)
        redirect project_url(@project).to_s
      else
        show :new, :title => ["projects", "new project"]
      end
    end

    get "/:project" do
      login_required unless current_project.public?

      if limit = Integrity.config.project_default_build_count
        @builds = current_project.sorted_builds.all(:limit => limit + 1)
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

      show :project, :title => ["projects", current_project.name]
    end

    get "/:project/all" do
      login_required unless current_project.public?

      @builds = current_project.sorted_builds
      @showing_all_builds = true

      show :project, :title => ["projects", current_project.name]
    end

    get "/:project/ping" do
      login_required unless current_project.public?

      if current_project.status != :success
        halt 412, current_project.status.to_s
      else
        current_project.last_build.sha1
      end
    end

    put "/:project" do
      login_required

      if current_project.update(params[:project_data])
        update_notifiers_of(current_project)
        redirect project_url(current_project).to_s
      else
        show :new, :title => ["projects", current_project.permalink, "edit"]
      end
    end

    delete "/:project" do
      login_required

      current_project.destroy
      redirect root_url.to_s
    end

    get "/:project/edit" do
      login_required

      show :new, :title => ["projects", current_project.permalink, "edit"]
    end

    post "/:project/builds" do
      login_required

      @build = current_project.build_head
      redirect build_url(@build).to_s
    end

    get "/:project/builds/:build" do
      login_required unless current_project.public?

      @status = current_build.status
      show :build, :title => ["projects", current_project.permalink,
        current_build.sha1_short]
    end

    get "/:project/builds/:build/raw" do
      login_required unless current_project.public?

      content_type :text
      current_build.output
    end

    post "/:project/builds/:build" do
      login_required

      @build = current_project.build(current_build.commit)
      redirect build_url(@build).to_s
    end

    delete "/:project/builds/:build" do
      login_required

      url = project_url(current_build.project).to_s
      current_build.destroy!
      redirect url
    end
  end
end
