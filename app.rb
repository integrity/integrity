require File.dirname(__FILE__) + "/lib/integrity"
require "sinatra"
require "helpers"
require "hacks"

set :root,   Integrity.root
set :public, Integrity.root / "public"
set :views,  Integrity.root / "views"

enable :sessions

include Integrity

configure :development do
  config = Integrity.root / "config" / "config.yml"
  Integrity.config = config if File.exists? config
end

configure do
  Integrity.new
end

not_found do
  status 404
  show :not_found, :title => "lost, are we?"
end

error do
  @error = request.env['sinatra.error']
  status 500
  show :error, :title => "something has gone terribly wrong"
end

before do
  # The browser only sends http auth data for requests that are explicitly
  # required to do so. This way we get the real values of +#logged_in?+ and
  # +#current_user+
  login_required if session[:user]
end

get "/" do
  @projects = Project.only_public_unless(authorized?)
  show :home, :title => "projects"
end

get "/login" do
  login_required
  session[:user] = current_user
  redirect "/"
end

get "/new" do
  login_required

  @project = Project.new
  show :new, :title => ["projects", "new project"]
end

post "/" do
  login_required
  
  @project = Project.new(params[:project_data])
  if @project.save
    @project.enable_notifiers(params["enabled_notifiers[]"], params["notifiers"])
    redirect project_path(@project)
  else
    show :new, :title => ["projects", "new project"]
  end
end

get "/:project" do
  login_required unless current_project.public?
  show :project, :title => ["projects", current_project.permalink]
end

get "/:project.rss" do
  header "Content-Type" => "application/rss+xml; charset=utf-8"
  login_required unless current_project.public? 
  builder :project
end

put "/:project" do
  login_required
  
  if current_project.update_attributes(params[:project_data])
    current_project.enable_notifiers(params["enabled_notifiers[]"], params["notifiers"])
    redirect project_url(current_project)
  else
    show :new, :title => ["projects", current_project.permalink, "edit"]
  end
end

delete "/:project" do
  login_required

  current_project.destroy
  redirect "/"
end

get "/:project/edit" do
  login_required

  show :new, :title => ["projects", current_project.permalink, "edit"]
end

post "/:project/push" do
  login_required
  
  content_type "text/plain"

  begin
    payload = JSON.parse(params[:payload] || "")

    if Integrity.config[:build_all_commits]
      payload["commits"].sort_by { |commit| Time.parse(commit["timestamp"]) }.each do |commit|
        current_project.build(commit["id"]) if payload["ref"] =~ /#{current_project.branch}/
      end
    else
      current_project.build(payload["after"]) if payload["ref"] =~ /#{current_project.branch}/
    end

    "Thanks, build started."
  rescue JSON::ParserError => exception
    invalid_payload!(exception.to_s)
  end
end

post "/:project/builds" do
  login_required

  current_project.build
  redirect project_url(@project)
end

get "/:project/builds/:build" do
  login_required unless current_project.public?
  show :build, :title => ["projects", current_project.permalink, current_build.short_commit_identifier]
end

get "/integrity.css" do
  header "Content-Type" => "text/css; charset=utf-8"
  sass :integrity
end

helpers do
  include Integrity::Helpers
end
