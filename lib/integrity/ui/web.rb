set :root,   Integrity.root / "lib/integrity/ui/web"
set :public, Integrity.root / "lib/integrity/ui/web/public"
set :views,  Integrity.root / "lib/integrity/ui/web/views"

configure do
  Integrity.new
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
  @project = Project.first(:permalink => params[:project])
  show :project, :title => ["projects", @project.permalink]
end

put "/:project" do
  @project = Project.first(:permalink => params[:project])
  if @project.update_attributes(filter_attributes_of(Project))
    redirect project_url(@project)
  else
    show :new, :title => ["projects", @project.permalink, "edit"]
  end
end

get "/:project/edit" do
  @project = Project.first(:permalink => params[:project])
  show :new, :title => ["projects", @project.permalink, "edit"]
end

post "/:project/build" do
  @project = Project.first(:permalink => params[:project])
  @project.build
  redirect project_url(@project)
end

get "/integrity.css" do
  header "Content-Type" => "text/css; charset=utf-8"
  sass :integrity
end

helpers do
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
  
  def filter_attributes_of(model)
    valid = model.properties.collect {|p| p.name.to_s }
    Hash[*params.dup.select {|k,_| valid.include?(k) }.flatten]
  end
end
