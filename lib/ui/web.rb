set :root,   Integrity.root / "lib/ui/web"
set :public, Integrity.root / "lib/ui/web/public"
set :views,  Integrity.root / "lib/ui/web/views"

get "/" do
  @projects = []
  show :home, :title => "Projects"
end

get "/new" do
  show :new, :title => "New Project"
end

get "/integrity.css" do
  header "Content-Type" => "text/css; charset=utf-8"
  sass :integrity
end

helpers do
  def show(view, options={})
    @title = options[:title]
    haml view
  end
end
