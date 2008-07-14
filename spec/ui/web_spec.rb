require File.dirname(__FILE__) + '/../spec_helper'

require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'

describe 'Web UI using Sinatra' do
  
  before(:each) do
    Integrity.stub!(:new) # don't connect to the database on UI tests
    require File.dirname(__FILE__) + '/../../lib/integrity/ui/web'
  end

  describe "Getting the home page" do
    describe "with no project available" do
      before(:each) do
        Project.stub!(:all).and_return([])
      end

      it "should be success" do
        get_it "/"
        @response.should be_ok
      end
      
      it "should look for projects in the db" do
        Project.should_receive(:all).and_return([])
        get_it "/"
      end
      
      it "should tell you that you have no projects" do
        get_it "/"
        @response.body.should =~ /None yet, huh?/
      end
      
      it "should have a link to add a new project" do
        get_it "/"
        @response.body.should =~ %r(<a href='/new'>.*</a>)
      end
    end
    
    describe "with available projects" do
      before(:each) do
        @project_1 = stub("Project", :name => "The 1st Project", :permalink => "the-1st-project")
        @project_2 = stub("Project", :name => "The 2nd Project", :permalink => "the-2nd-project")
        Project.stub!(:all).and_return([@project_1, @project_2])
      end
      
      it "should be success" do
        get_it "/"
        @response.should be_ok
      end
      
      it "should load the projects from the db" do
        Project.should_receive(:all).and_return([@project_1, @project_2])
        get_it "/"
      end
      
      it "should show a list of the projects" do
        get_it "/"
        @response.body.should =~ /<ul id='projects'>/
      end
      
      it "should have a link to both projects" do
        get_it "/"
        @response.body.should =~ %r(<a href='/the-1st-project'>The 1st Project</a>)
        @response.body.should =~ %r(<a href='/the-2nd-project'>The 2nd Project</a>)
      end

      it "should have a link to add a new project" do
        get_it "/"
        @response.body.should =~ %r(<a href='/new'>.*</a>)
      end
    end
  end
  
  describe "getting the 'new project' form" do
    before do
      @project = stub("project", :name => nil, :uri => nil, :branch => "master", :command => "rake", :public? => true)
    end
    
    it "should render successfully" do
      get_it "/new"
      @response.should be_ok
    end
    
    it "should initialize a new Project instance" do
      Project.should_receive(:new).and_return(@project)
      get_it "/new"
    end
    
    it "should render a form that posts back to '/'" do
      get_it "/new"
      @response.should =~ %r(<form action='/' method='post'>)
    end    
    
    it "should have all the necessary fields" do
      get_it "/new"
      @response.should =~ %r(<input class='text' id='project_name' name='name' type='text' />)
      @response.should =~ %r(<input class='text' id='project_repository' name='uri' type='text' />)
      @response.should =~ %r(<input class='text' id='project_branch' name='branch' type='text' value='master' />)
      @response.should =~ %r(input checked='checked' class='checkbox' id='project_privacy' name='public' type='checkbox' />)
      @response.should =~ %r(<textarea id='project_build_script' name='command' rows='1' type='text'>rake</textarea>)
    end
  end
  
  describe "creating a new project" do
    before do
      @project = stub("project", :name => nil, :uri => nil, :branch => "master", :command => "rake", :public? => true, :permalink => "blah")
      Project.stub!(:new).with(an_instance_of(Hash)).and_return(@project)
    end
    
    describe "with invalid attributes" do
      before { @project.stub!(:save).and_return(false) }
      
      it "should re-render the 'new' view" do
        post_it "/"
        @response.should be_ok # how do I test I'm rendering a certain view?
      end
    end
    
    describe "with valid attributes" do
      before { @project.stub!(:save).and_return(true) }
      
      it "should redirect to the new project's page" do
        post_it "/"
        @response.location.should == "/blah"
      end
    end
  end
  
  describe "getting a project page" do
    before do
      @project = stub("project", :name => "Integrity", :permalink => "integrity", :builds => [])
      Project.stub!(:first).with(:permalink => "integrity").and_return(@project)
    end
    
    it "should be success" do
      get_it "/integrity"
      @response.should be_ok
    end
  end
  
  describe "manually building a project" do
    before do
      @project = stub("project", :permalink => "integrity", :build => true)
      Project.stub!(:first).with(:permalink => "integrity").and_return(@project)
    end
    
    it "should build the project" do
      @project.should_receive(:build)
      post_it "/integrity/build"
    end
    
    it "should redirect back to the project" do
      post_it "/integrity/build"
      @response.location.should == "/integrity"
    end
  end
  
  describe "getting the site stylesheet" do
    it "should render successfully" do
      get_it "/integrity.css"
      @response.should be_ok
    end

    it "should render with the text/css mime type" do
      get_it "/integrity.css"
      @response.headers["Content-Type"].should =~ %r(^text/css)
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
      before { @context.stub!(:pages).and_return([["home", "/"], ["about", "/about"], ["other page", "/other"]]) }
      
      it "should, when passed only one argument, return a single element array with the argument untouched" do
        @context.breadcrumbs("test").should == ["test"]
      end
      
      it "should, when passed a multi-element array, search for all except the last one in the pages list" do
        @context.breadcrumbs("home", "other page", "test").should == ['<a href="/">home</a>', '<a href="/other">other page</a>', 'test']
      end
      
      it "should give the arguments in the given order, no matter how they appear on the #pages list" do
        @context.breadcrumbs("about", "home", "other page").should == ['<a href="/about">about</a>', '<a href="/">home</a>', 'other page']
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
      before { @project = stub("Project", :permalink => "cuack") }
      
      it "should receive a project and return a link to it" do
        @context.project_url(@project).should == "/cuack"
      end
      
      it "should add whatever other arguments are passed as tokens in the path" do
        @context.project_url(@project, :build, :blah).should == "/cuack/build/blah"
      end
    end
  end
end
