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
    redirect "/#{@project.id}"
  else
    show :new, :title => ["projects", "new project"]
  end
end

get "/:project_id" do
  @project = Project.get(params[:project_id])
  show :project, :title => ["projects", @project.name]
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
    @pages ||= [["projects", "/"], ["new project", "/new"]]
  end
  
  def breadcrumbs(*crumbs)
    crumbs[0..-2].map do |crumb|
      page_data = pages.detect {|c| c.first == crumb }
      %Q(<a href="#{page_data.last}">#{page_data.first}</a>)
    end + [crumbs.last]
  end
  
  def cycle(*values)
    @cycles ||= {}
    @cycles[values] ||= -1 # first value returned is 0
    next_value = @cycles[values] = (@cycles[values] + 1) % values.size
    values[next_value]
  end
end
