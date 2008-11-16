require File.dirname(__FILE__) + '/lib/integrity'
require 'sinatra'
require 'diddies'
require 'hacks'

set :root,   Integrity.root
set :public, Integrity.root / "public"
set :views,  Integrity.root / "views"

enable :sessions

include Integrity

configure do
  config = Integrity.root / "config.yml"
  Integrity.config = config if File.exists? config
  Integrity.new
end

not_found do
  status 404
  show :not_found, :title => "lost, are we?"
end

before do
  # The browser only sends http auth data for requests that are explicitly
  # required to do so. This way we get the real values of +#logged_in?+ and
  # +#current_user+
  login_required if session[:user]
end

get "/" do
  @projects = Project.all(authorized? ? {} : { :public => true })
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
    redirect project_url(@project)
  else
    show :new, :title => ["projects", "new project"]
  end
end

get "/:project" do
  login_required unless current_project.public?
  show :project, :title => ["projects", current_project.permalink]
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
  content_type 'text/plain'

  begin
    payload = JSON.parse(params[:payload] || "")
    payload['commits'].reverse.each do |commit|
      current_project.build(commit['id']) if payload['ref'] =~ /#{current_project.branch}/
    end
    'Thanks, build started.'
  rescue JSON::ParserError => exception
    invalid_payload!(exception.to_s)
  end
end

post "/:project/builds" do
  login_required

  current_project.build
  redirect project_url(@project)
end

get '/:project/builds/:build' do
  login_required unless current_project.public?
  show :build, :title => ["projects", current_project.permalink, current_build.short_commit_identifier]
end

get "/integrity.css" do
  header "Content-Type" => "text/css; charset=utf-8"
  sass :integrity
end

helpers do
  include Rack::Utils
  include Sinatra::Authorization
  alias_method :h, :escape_html

  def authorization_realm
    "Integrity"
  end

  def authorized?
    return true unless Integrity.config[:use_basic_auth]
    !!request.env['REMOTE_USER']
  end

  def authorize(user, password)
    if Integrity.config[:hash_admin_password]
      password = Digest::SHA1.hexdigest(password)
    end

    !Integrity.config[:use_basic_auth] ||
    (Integrity.config[:admin_username] == user &&
      Integrity.config[:admin_password] == password)
  end

  def unauthorized!(realm=authorization_realm)
    header 'WWW-Authenticate' => %(Basic realm="#{realm}")
    throw :halt, [401, show(:unauthorized, :title => "incorrect credentials")]
  end

  def invalid_payload!(msg=nil)
    throw :halt, [422, msg || 'No payload given']
  end

  def current_project
    @project ||= Project.first(:permalink => params[:project]) or raise Sinatra::NotFound
  end

  def current_build
    @build ||= current_project.builds.first(:commit_identifier => params[:build]) or raise Sinatra::NotFound
  end

  def show(view, options={})
    @title = breadcrumbs(*options[:title])
    haml view
  end

  def pages
    @pages ||= [["projects", "/"], ["new project", "/new"]]
  end

  def breadcrumbs(*crumbs)
    crumbs[0..-2].map do |crumb|
      if page_data = pages.detect {|c| c.first == crumb }
        %Q(<a href="#{page_data.last}">#{page_data.first}</a>)
      elsif @project && @project.permalink == crumb
        %Q(<a href="#{project_url(@project)}">#{@project.permalink}</a>)
      end
    end + [crumbs.last]
  end

  def cycle(*values)
    @cycles ||= {}
    @cycles[values] ||= -1 # first value returned is 0
    next_value = @cycles[values] = (@cycles[values] + 1) % values.size
    values[next_value]
  end

  def project_url(project, *path)
    "/" << [project.permalink, *path].join("/")
  end

  def push_url_for(project)
    Addressable::URI.parse(Integrity.config[:base_uri]).join("#{project_url(project)}/push").to_s
  end

  def build_url(build)
    "/#{build.project.permalink}/builds/#{build.commit_identifier}"
  end

  def filter_attributes_of(model)
    valid = model.properties.collect {|p| p.name.to_s }
    Hash[*params.dup.select {|k,_| valid.include?(k) }.flatten]
  end

  def errors_on(object, field)
    return "" unless errors = object.errors.on(field)
    errors.map {|e| e.gsub(/#{field} /i, "") }.join(", ")
  end

  def error_class(object, field)
    object.errors.on(field).nil? ? "" : "with_errors"
  end
  
  def checkbox(name, condition, extras={})
    attrs = { :name => name, :type => "checkbox" }.merge(condition ? { :checked => "checked" } : {})
    attrs.merge(extras)
  end

  def bash_color_codes(string)
    string.gsub("\e[0m", '</span>').
      gsub("\e[31m", '<span class="color31">').
      gsub("\e[32m", '<span class="color32">').
      gsub("\e[33m", '<span class="color33">').
      gsub("\e[34m", '<span class="color34">').
      gsub("\e[35m", '<span class="color35">').
      gsub("\e[36m", '<span class="color36">').
      gsub("\e[37m", '<span class="color37">')
  end

  def pretty_date(date_time)
    today = Date.today
    if date_time.day == today.day && date_time.month == today.month && date_time.year == today.year
      "today"
    elsif date_time.day == today.day - 1 && date_time.month == today.month && date_time.year == today.year
      "yesterday"
    else
      date_time.strftime("on %b %d%o")
    end
  end
  
  def notifier_form(notifier)
    haml(notifier.to_haml, :layout => :notifier, :locals => { 
      :config => current_project.config_for(notifier), 
      :notifier => "#{notifier.to_s.split(/::/).last}", 
      :enabled => current_project.notifies?(notifier) 
    })
  end
end
