set :root,   Integrity.root / "lib/integrity/ui/web"
set :public, Integrity.root / "lib/integrity/ui/web/public"
set :views,  Integrity.root / "lib/integrity/ui/web/views"

configure do
  Integrity.new
end

not_found do
  status 404
  content_type 'text/plain'
  'Not Found'
end

include Integrity

get "/" do
  @projects = Project.all
  show :home, :title => "projects"
end

get "/new" do
  @project = Project.new
  show :new, :title => ["projects", "new project"]
end

post "/" do
  @project = Project.new(params)
  if @project.save
    redirect project_url(@project)
  else
    show :new, :title => ["projects", "new project"]
  end
end

get "/:project" do
  show :project, :title => ["projects", current_project.permalink]
end

put "/:project" do
  if current_project.update_attributes(filter_attributes_of(Project))
    redirect project_url(current_project)
  else
    show :new, :title => ["projects", current_project.permalink, "edit"]
  end
end

delete "/:project" do
  current_project.destroy
  redirect "/"
end

get "/:project/edit" do
  show :new, :title => ["projects", current_project.permalink, "edit"]
end

post "/:project/builds" do
  current_project.build
  redirect project_url(@project)
end

get '/:project/builds/:build' do
  @build = current_project.builds.first(:commit_identifier => params[:build])
  raise Sinatra::NotFound unless @build
  show :build, :title => 'Some build'
end

get "/integrity.css" do
  header "Content-Type" => "text/css; charset=utf-8"
  sass :integrity
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  def current_project
    @project ||= Project.first(:permalink => params[:project]) or raise Sinatra::NotFound
  end
  
  def show(view, options={})
    @title = breadcrumbs(*options[:title])
    haml view
  end
  
  def pages
    @pages ||= [["projects", "/"], ["new project", "/new"], ["edit", nil]]
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
  
  def checkbox(name, condition)
    { :name => name, :type => "checkbox" }.merge(condition ? { :checked => "checked" } : {})
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
end
