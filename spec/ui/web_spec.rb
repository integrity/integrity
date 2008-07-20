require File.dirname(__FILE__) + '/../spec_helper'

require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'

describe 'Web UI using Sinatra' do
  
  def mock_project(messages={})
    messages = {
      :name => "Integrity", 
      :permalink => "integrity", 
      :new_record? => false, 
      :uri => "git://github.com/foca/integrity.git", 
      :branch => "master", 
      :command => "rake", 
      :public? => true,
      :builds => [],
      :build => nil,
      :update_attributes => true,
      :save => true,
      :destroy => nil,
      :errors => stub("errors", :on => nil)
    }.merge(messages)
    
    @project ||= stub("project", messages)
  end
  
  before do
    Integrity.stub!(:new) # don't connect to the database on UI tests
    require File.dirname(__FILE__) + '/../../lib/integrity/ui/web'
  end
  
  after { @project = nil }

  describe "Getting the home page" do
    describe "with no project available" do
      before do
        Project.stub!(:all).and_return([])
      end

      it "should be success" do
        get_it "/"
        status.should == 200
      end
      
      it "should look for projects in the db" do
        Project.should_receive(:all).and_return([])
        get_it "/"
      end
      
      it "should tell you that you have no projects" do
        get_it "/"
        body.should =~ /None yet, huh?/
      end
      
      it "should have a link to add a new project" do
        get_it "/"
        body.should =~ %r(<a href='/new'>.*</a>)
      end
    end
    
    describe "with available projects" do
      before do
        @project_1 = stub("project", :name => "The 1st Project", :permalink => "the-1st-project")
        @project_2 = stub("project", :name => "The 2nd Project", :permalink => "the-2nd-project")
        Project.stub!(:all).and_return([@project_1, @project_2])
      end
      
      it "should be success" do
        get_it "/"
        status.should == 200
      end
      
      it "should load the projects from the db" do
        Project.should_receive(:all).and_return([@project_1, @project_2])
        get_it "/"
      end
      
      it "should show a list of the projects" do
        get_it "/"
        body.should =~ /<ul id='projects'>/
      end
      
      it "should have a link to both projects" do
        get_it "/"
        body.should =~ %r(<a href='/the-1st-project'>The 1st Project</a>)
        body.should =~ %r(<a href='/the-2nd-project'>The 2nd Project</a>)
      end

      it "should have a link to add a new project" do
        get_it "/"
        body.should =~ %r(<a href='/new'>.*</a>)
      end
    end
  end
  
  describe "getting the 'new project' form" do
    it "should render successfully" do
      get_it "/new"
      status.should == 200
    end
    
    it "should initialize a new Project instance" do
      Project.should_receive(:new).and_return mock_project(:new_record? => true, :name => nil, :uri => nil)
      get_it "/new"
    end
    
    it "should render a form that posts back to '/'" do
      get_it "/new"
      body.should =~ %r(<form action='/' method='post'>)
    end    
    
    it "should have all the necessary fields" do
      get_it "/new"
      body.should =~ %r(<input class='text' id='project_name' name='name' type='text' value='' />)
      body.should =~ %r(<input class='text' id='project_repository' name='uri' type='text' value='' />)
      body.should =~ %r(<input class='text' id='project_branch' name='branch' type='text' value='master' />)
      body.should =~ %r(input checked='checked' class='checkbox' id='project_public' name='public' type='checkbox' />)
      body.should =~ %r(<textarea cols='40' id='project_build_script' name='command' rows='1'>rake</textarea>)
    end
  end
  
  describe "creating a new project" do
    before { Project.stub!(:new).and_return(mock_project) }

    it "should re-render the 'new' view when the project has invalid attributes" do
      mock_project.stub!(:save).and_return(false)
      post_it "/"
      status.should == 200
    end
    
    it "should redirect to the new project's page when the project has valid attributes" do
      mock_project.stub!(:save).and_return(true)
      post_it "/"
      location.should == "/integrity"
    end

    it "display error messages" do
      mock_project.should_receive(:save).and_return(false)
      mock_project.errors.stub!(:on).with(:name).and_return('Name is already taken')
      post_it "/"
      body.should =~ /with_errors/
    end
  end
  
  describe "getting a project page" do
    it "should be success" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      get_it "/integrity"
      status.should == 200
    end
  end
  
  describe "getting a project's edit form" do
    before { Project.stub!(:first).with(:permalink => "integrity").and_return mock_project }
    
    it "should be success" do
      get_it "/integrity/edit"
      status.should == 200
    end
    
    it "should render the form pointed at the projects permalink" do
      get_it "/integrity/edit"
      body.should =~ %r(form action='/integrity')
    end
    
    it "should use http PUT as the form method" do
      get_it "/integrity/edit"
      body.should =~ %r(form.*method='post')
      body.should =~ %r(input name='_method' type='hidden' value='put')
    end
    
    it "should prepopulate the form with the properties of the project" do
      get_it "/integrity/edit"
      body.should =~ %r(<input class='text' id='project_name' name='name' type='text' value='Integrity' />)
      body.should =~ %r(<input class='text' id='project_repository' name='uri' type='text' value='git://github.com/foca/integrity.git' />)
      body.should =~ %r(<input class='text' id='project_branch' name='branch' type='text' value='master' />)
      body.should =~ %r(input checked='checked' class='checkbox' id='project_public' name='public' type='checkbox' />)
      body.should =~ %r(<textarea cols='40' id='project_build_script' name='command' rows='1'>rake</textarea>)
    end
  end
  
  describe "updating a project" do
    before do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
    end
    
    it "should redirect to the project page if the update is valid" do
      mock_project.should_receive(:update_attributes).and_return(true)
      put_it "/integrity"
      location.should == "/integrity"
    end
    
    it "should re-render the form if the update isn't valid" do
      mock_project.should_receive(:update_attributes).and_return(false)
      put_it "/integrity"
      status.should == 200
    end
    
    it "display error messages" do
      mock_project.should_receive(:update_attributes).and_return(false)
      mock_project.errors.stub!(:on).with(:name).and_return("Name can't be blank")
      put_it "/integrity"
      body.should =~ /with_errors/
    end
  end
  
  describe "deleting a project" do
    it "should load the project" do
      Project.should_receive(:first).with(:permalink => "integrity").and_return mock_project
      delete_it "/integrity"
    end
    
    it "should destroy the project" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      mock_project.should_receive(:destroy)
      delete_it "/integrity"
    end
    
    it "should redirect to the home page" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      delete_it "/integrity"
      location.should == "/"
    end
  end
  
  describe "manually building a project" do
    it "should build the project" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      mock_project.should_receive(:build)
      post_it "/integrity/build"
    end
    
    it "should redirect back to the project" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      post_it "/integrity/build"
      follow!
      status.should == 200
    end
  end
  
  describe "getting the site stylesheet" do
    it "should render successfully" do
      get_it "/integrity.css"
      status.should == 200
    end

    it "should render with the text/css mime type" do
      get_it "/integrity.css"
      headers["Content-Type"].should =~ %r(^text/css)
    end
  end
  
  describe "Helpers" do
    before { @context = Sinatra::EventContext.new(stub("request"), stub("response", :body= => nil), stub("route params")) }
    
    describe "#show" do
      before do
        @context.stub!(:haml)
        @context.stub!(:breadcrumbs).and_return(['<a href="/">home</a>', 'test'])
      end
      after { @context.instance_variable_set(:@title, nil) }
      
      it "should receive a haml view" do
        @context.should_receive(:haml).with(:home)
        @context.show(:home)
      end
      
      it "should accept an optional 'title' setting" do
        @context.show(:home, :title => ["home", "test"])
        @context.instance_variable_get(:@title).should == ['<a href="/">home</a>', 'test']
      end
    end
    
    describe "#pages" do
      it "should list a series of pairs [title, url]" do
        @context.pages.all? {|p| p.should respond_to(:first, :last) }
      end
    end
    
    describe "#breadcrumbs" do
      before do
        @project = stub("Project", :permalink => "the-great-project")
        @context.instance_variable_set(:@project, @project)
        @context.stub!(:pages).and_return([["home", "/"], ["about", "/about"], ["other page", "/other"]]) 
      end
      
      it "should, when passed only one argument, return a single element array with the argument untouched" do
        @context.breadcrumbs("test").should == ["test"]
      end
      
      it "should, when passed a multi-element array, search for all except the last one in the pages list" do
        @context.breadcrumbs("home", "other page", "test").should == ['<a href="/">home</a>', '<a href="/other">other page</a>', 'test']
      end
      
      it "should give the arguments in the given order, no matter how they appear on the #pages list" do
        @context.breadcrumbs("about", "home", "other page").should == ['<a href="/about">about</a>', '<a href="/">home</a>', 'other page']
      end
      
      it "should use #project_url if one of the breadcrumbs isn't in the pages array and matches the current project permalink" do
        @context.should_receive(:project_url).with(@project).and_return("/the-great-project")
        @context.breadcrumbs("home", "the-great-project", "edit")
      end
    end
    
    describe "#cycle" do
      after do
        @context.instance_eval { @cycles = nil }
      end
      
      it "should return the first value the first time" do
        @context.cycle("even", "odd").should == "even"
      end
      
      it "should not mix two different cycles" do
        @context.cycle("even", "odd").should == "even"
        @context.cycle("red", "green", "blue").should == "red"
      end
      
      it "should return a cycling element each time its called with the same set of arguments" do
        @context.cycle("red", "green", "blue").should == "red"
        @context.cycle("red", "green", "blue").should == "green"
        @context.cycle("red", "green", "blue").should == "blue"
        @context.cycle("red", "green", "blue").should == "red"
      end
    end
    
    describe "#project_url" do
      it "should receive a project and return a link to it" do
        @context.project_url(mock_project).should == "/integrity"
      end
      
      it "should add whatever other arguments are passed as tokens in the path" do
        @context.project_url(mock_project, :build, :blah).should == "/integrity/build/blah"
      end
    end
    
    describe "#filter_attributes_of" do
      before do
        @context.stub!(:params).and_return("some" => "arguments", "are" => "better", "left" => "unspoken")
        @model = stub("a class", :properties => [stub("prop", :name => "some"), stub("prop", :name => "left")])
      end
      
      it "should return a hash with only the keys that are properties of the model" do
        @context.filter_attributes_of(@model).should == { "some" => "arguments", "left" => "unspoken" }
      end
    end
    
    describe "#error_class" do
      it "should return an empty string when the object doesn't have errors on the attribute" do
        mock_project.errors.stub!(:on).with(:some_attribute).and_return(nil)
        @context.error_class(mock_project, :some_attribute).should == ""
      end

      it "should return 'with_errors' when the object has errors on the attribute" do
        mock_project.errors.stub!(:on).with(:name).and_return(["Name can't be blank", "Name must be unique"])
        @context.error_class(mock_project, :name).should == "with_errors"
      end
    end
    
    describe "#errors_on" do
      it "should return an empty string if the object doesn't have errors on the attribute" do
        mock_project.errors.stub!(:on).with(:uri).and_return(nil)
        @context.errors_on(mock_project, :uri).should == ""
      end
      
      it "should return the errors messages (without the field names) separated with commas when it has errors" do
        mock_project.errors.stub!(:on).with(:name).and_return(["Name can't be blank", "Name must be unique"])
        @context.errors_on(mock_project, :name).should == "can't be blank, must be unique"
      end
    end
    
    describe "#checkbox" do
      it "should generate the correct attributes for a checkbox" do
        @context.checkbox(:cuack, true).should == { :name => :cuack, :type => "checkbox", :checked => "checked" }
        @context.checkbox(:cuack, false).should == { :name => :cuack, :type => "checkbox" }
      end
    end
    
    describe "#bash_color_codes" do
      it "should replace [0m for a closing span tag" do
        @context.bash_color_codes("<span>something[0m").should == '<span>something</span>'
      end
      
      it "should replace [XXm for a span.colorXX, for XX in 31..37" do
        (31..37).each do |color|
          @context.bash_color_codes("[#{color}msomething</span>").should == %Q(<span class="color#{color}">something</span>)
        end
      end
    end
  end
end
