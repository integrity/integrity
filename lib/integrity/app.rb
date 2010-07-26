module Integrity
  class App < Sinatra::Base
    set     :root, File.expand_path("../../..", __FILE__)
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
      show :home, :title => "projects"
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

      show :project, :title => ["projects", current_project.name]
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
