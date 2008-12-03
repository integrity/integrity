require File.dirname(__FILE__) + '/spec_helper'

require 'sinatra'
require 'sinatra/test/rspec'
require Integrity.root / 'app'


describe 'Web App' do
  include AppSpecHelper

  before(:each) do
    Integrity.stub!(:new)
    disable_basic_auth!
  end

  after(:each) { @project = nil }

  describe 'With basic auth enabled' do
    before(:each) do
      enable_basic_auth!
    end

    it 'should propose to login if not logged in' do
      get_it '/'
      @response.should have_tag('#footer a[@href="/login"]', 'Log In')
    end

    it 'should say hello to the logged in user' do
      get_it '/', :env => {'REMOTE_USER' => 'user'}
      @response.should have_tag('strong', 'user')
    end
  end

  describe 'With basic auth disabled' do
    before(:each) do
      disable_basic_auth!
    end

    it 'should not display anything related to auth' do
      get_it '/'
      @response.should_not have_tag('#footer')
    end
  end

  describe "GET /" do
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
        @response.should have_tag(".blank_slate", /none yet/i)
      end

      it "should have a link to add a new project" do
        get_it "/"
        @response.should have_tag(".blank_slate a[@href=/new]", /create your first project/i)
      end
    end

    describe "with available projects" do
      before do
        @project_1 = stub("project", :name => "The 1st Project", :permalink => "the-1st-project", :status => :success, :building? => true, :last_build => mock_build)
        @project_2 = stub("project", :name => "The 2nd Project", :permalink => "the-2nd-project", :status => :failed, :building? => false, :last_build => mock_build)
        Project.stub!(:all).and_return([@project_1, @project_2])
      end

      it "should be success" do
        get_it "/"
        status.should == 200
      end

      it "should load the public projects from the db" do
        enable_basic_auth!
        Project.should_receive(:all).with(:public => true).and_return([@project_1, @project_2])
        get_it "/"
      end

      it "should load *all* the projects from the db *if the user has authenticated*" do
        Project.should_receive(:all).with({}).and_return([@project_1, @project_2])
        get_it "/"
      end

      it "should show a list of the projects" do
        get_it "/"
        body.should have_tag("ul#projects") do |projects|
          projects.should have_tag("li > a", /the (1st|2nd) project/i, :count => 2)
        end
      end

      it "should mark projects being built as such" do
        get_it "/"
        body.should have_tag('#projects li.building a', :count => 1)
      end

      it "should have a link to add a new project" do
        get_it "/"
        body.should have_tag("#new a[@href=/new]", /add a new project/i)
      end
    end
  end

  describe "GET /login" do
    it "should require authentication" do
      enable_basic_auth!
      get_it "/login"
      status.should == 401
    end

    it "should redirect to '/' on successful auth" do
      get_it "/login"
      location.should == "/"
    end

    it "should store the username on the session" do
      pending "how do I test the session?!"
      get_it "/login"
    end
  end

  describe "GET /new" do
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
      body.should have_tag("form[@action='/'][@method='post']") do |form|
        form.should have_textfield("project_name").named("project_data[name]").with_value("")
        form.should have_textfield("project_repository").named("project_data[uri]").with_value("")
        form.should have_textfield("project_branch").named("project_data[branch]").with_value("master")
        form.should have_checkbox("project_public").named("project_data[public]").checked
        form.should have_textarea("project_build_script").named("project_data[command]").with_value(/rake/)
      end
    end

    it "should require authentication" do
      enable_basic_auth!
      get_it "/new"
      status.should == 401
    end
  end

  describe "POST /" do
    before do
      Integrity.stub!(:config).and_return(:base_uri => 'http://foo.org')
      Project.stub!(:new).and_return(mock_project)
    end

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
    
    it "should enable the notifiers" do
      mock_project.stub!(:save).and_return(true)
      mock_project.should_receive(:enable_notifiers)
      post_it "/"
    end

    it "should display error messages" do
      mock_project.should_receive(:save).and_return(false)
      mock_project.errors.stub!(:on).with(:name).and_return('Name is already taken')
      post_it "/"
      body.should have_tag("p.required.with_errors") do |field|
        field.should have_tag("label", /is already taken/)
      end
    end

    it "should require authentication" do
      enable_basic_auth!
      post_it "/"
      status.should == 401
    end
  end

  describe "GET /:project" do
    it "should load the project from the database" do
      Project.should_receive(:first).with(:permalink => "integrity").and_return(mock_project)
      get_it "/integrity"
    end

    it 'should be 404 if unknown project' do
      Project.stub!(:first).and_return(nil)
      get_it '/integrity'
      status.should == 404
    end

    describe 'without builds' do
      before(:each) do
        Project.stub!(:first).with(:permalink => "integrity").and_return(mock_project)
      end

      it "should be success" do
        get_it "/integrity"
        status.should == 200
      end

      it "should have a form to create a new build" do
        get_it "/integrity"
        body.should have_tag("form.blank_slate[@action='/integrity/builds'][@method='post']") do |form|
          form.should have_tag("button[@type='submit']", /manual build/)
        end
      end
    end

    describe 'with builds' do
      before(:each) do
        @build_successful = mock_build(:status => :success)
        @build_failed = mock_build(:status => :failed)
        @project = mock_project(
          :last_build => @build_successful,
          :builds     => [@build_successful, @build_failed],
          :previous_builds => []
        )
        Project.stub!(:first).with(:permalink => "integrity").and_return(@project)
      end

      it "should be success" do
        get_it "/integrity"
        status.should == 200
      end

      it 'should have a container with class "success" if the latest build was successful' do
        @project.last_build.stub!(:status).and_return(:success)
        get_it '/integrity'
        body.should have_tag('#last_build.success')
      end

      it 'should have a container with class "failed" if the latest build failed' do
        @project.last_build.stub!(:status).and_return(:failed)
        get_it '/integrity'
        body.should have_tag('#last_build.failed')
      end

      it 'should display the output of the latest build' do
        @project.last_build.should_receive(:output).and_return('blabla')
        get_it '/integrity'
        body.should have_tag('pre.output', /^blabla/)
      end

      it "should have a form to create a new build" do
        get_it "/integrity"
        body.should have_tag("form[@action='/integrity/builds'][@method='post']") do |form|
          form.should have_tag("button[@type='submit']", /manual build/i)
        end
      end

      describe 'with previous builds' do
        before(:each) do
          @previous_build_successful = mock_build(:status => :success,
            :commit_identifier => 'e39f64487e8de857e8b00947cf1b5d47a0480062')
          @previous_build_failed = mock_build(:status => :fail,
            :commit_identifier => 'e63a7711af672b5287cdcbbd47afb36952b88f10')
          @project.stub!(:previous_builds).
            and_return([@previous_build_successful, @previous_build_failed])
        end

        it 'should list every previous builds' do
          get_it '/integrity'
          body.should have_tag('h2', 'Previous builds')
          body.should have_tag('ul#previous_builds > li', :count => 2)
        end

        it 'should display the short commit identifier of each previous builds' do
          get_it '/integrity'
          body.should have_tag('ul#previous_builds') do |ul|
            ul.should have_tag('li a', /e39f64/)
            ul.should have_tag('li a', /e63a77/)
          end
        end

        it "should use class depending on build on build's status" do
          mock_project.stub!(:public).and_return(true)
          get_it '/integrity'
          body.should have_tag('ul#previous_builds') do |ul|
            ul.should have_tag('li.success a')
            ul.should have_tag('li.fail a')
          end
        end

        it 'should link to the page of each build' do
          get_it '/integrity'
          body.should have_tag('ul#previous_builds') do |ul|
            ul.should have_tag('li a[@href=/integrity/builds/e39f64487e8de857e8b00947cf1b5d47a0480062')
            ul.should have_tag('li a[@href=/integrity/builds/e63a7711af672b5287cdcbbd47afb36952b88f10')
          end
        end
      end
    end
  end

  describe "GET /:project/edit" do
    before do
      Integrity.stub!(:config).and_return(:base_uri => 'http://foo.org')
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
    end

    it "should be success" do
      get_it "/integrity/edit"
      status.should == 200
    end

    it "should require authentication" do
      enable_basic_auth!
      get_it "/integrity/edit"
      status.should == 401
    end

    it 'should be 404 if unknown project' do
      Project.stub!(:first).and_return(nil)
      get_it '/integrity/edit'
      status.should == 404
    end

    it "should render the form pointed at the projects permalink" do
      get_it "/integrity/edit"
      body.should have_tag("form[@action='/integrity'][@method='post']") do |form|
        form.should have_tag("input[@name='_method'][@type='hidden'][@value='put']")
        
        form.should have_textfield("project_name").named("project_data[name]").with_value("Integrity")
        form.should have_textfield("project_repository").named("project_data[uri]").with_value("git://github.com/foca/integrity.git")
        form.should have_textfield("project_branch").named("project_data[branch]").with_value("master")
        form.should have_checkbox("project_public").named("project_data[public]").checked
        form.should have_textarea("project_build_script").named("project_data[command]").with_value(/rake/)
      end
    end

    it 'should display the push URL' do
      get_it '/integrity/edit'
      body.should have_tag('h2', 'Push URL')
      body.should have_tag('code#push_url', 'http://foo.org/integrity/push')
    end
  end

  describe "PUT /:project" do
    before do
      Integrity.stub!(:config).and_return(:base_uri => 'http://foo.org')
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

    it "should enable the notifiers" do
      mock_project.stub!(:update_attributes).and_return(true)
      mock_project.should_receive(:enable_notifiers)
      put_it "/integrity"
    end
    
    it "display error messages" do
      mock_project.should_receive(:update_attributes).and_return(false)
      mock_project.errors.stub!(:on).with(:name).and_return("Name can't be blank")
      put_it "/integrity"
      body.should have_tag("p.required.with_errors") do |field|
        field.should have_tag("label", /can't be blank/)
      end
    end

    it 'should be 404 if unknown project' do
      Project.stub!(:first).and_return(nil)
      put_it '/integrity'
      status.should == 404
    end

    it "should require authentication" do
      enable_basic_auth!
      put_it "/integrity"
      status.should == 401
    end
  end

  describe "DELETE /:project" do
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

    it 'should be 404 if unknown project' do
      Project.stub!(:first).and_return(nil)
      delete_it '/integrity'
      status.should == 404
    end

    it "should require authentication" do
      enable_basic_auth!
      delete_it "/integrity"
      status.should == 401
    end
  end

  describe "POST /:project/push" do
    def payload
      <<-EOS
      {
        "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
        "repository": {
          "url": "http://github.com/defunkt/github",
          "name": "github",
          "description": "You're lookin' at it.",
          "watchers": 5,
          "forks": 2,
          "private": 1,
          "owner": {
            "email": "chris@ozmm.org",
            "name": "defunkt"
          }
        },
        "commits": [
          {
            "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
            "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
            "author": {
              "email": "chris@ozmm.org",
              "name": "Chris Wanstrath"
            },
            "message": "okay i give in",
            "timestamp": "2008-02-15T14:57:17-08:00",
            "added": ["filepath.rb"]
          },
          {
            "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
            "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
            "author": {
              "email": "chris@ozmm.org",
              "name": "Chris Wanstrath"
            },
            "message": "update pricing a tad",
            "timestamp": "2008-02-15T14:36:34-08:00"
          }
        ],
        "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
        "ref": "refs/heads/master"
      }
      EOS
    end

    before do
      Project.stub!(:first).with(:permalink => "github").and_return mock_project
      Integrity.config[:build_all_commits] = true
    end

    it "should require authentication" do
      enable_basic_auth!
      post_it '/github/push', :payload => payload
      status.should == 401
    end

    it 'should be successful' do
      post_it '/github/push', :payload => payload
      status.should == 200
    end

    it 'should return a confirmation message' do
      post_it '/github/push', :payload => payload
      body.should == 'Thanks, build started.'
    end

    it 'should be 422 without payload' do
      post_it '/github/push'
      status.should == 422
    end

    it 'should find the Project by its name' do
      Integrity::Project.should_receive(:first).with(:permalink => 'github').and_return(@project)
      post_it '/github/push', :payload => payload
    end

    it 'should be 404 if unknown project' do
      Integrity::Project.stub!(:first).and_return(nil)
      post_it '/github/push', :payload => payload
      status.should == 404
    end

    it 'should make a new build for each commit' do
      @project.should_receive(:build).with('41a212ee83ca127e3c8cf465891ab7216a705f59')
      @project.should_receive(:build).with('de8251ff97ee194a289832576287d6f8ad74e3d0')
      post_it '/github/push', :payload => payload
    end

    it "should not build the project if the commit isn't to the branch we're monitoring" do
      @project.should_not_receive(:build)
      post_it '/github/push', :payload => payload.sub('refs/heads/master', 'refs/heads/unstable')
    end

    describe 'When build_all_commits is false' do
      before(:each) { Integrity.config[:build_all_commits] = false }

      it 'should only build the after sha1' do
        @project.should_receive(:build).with('41a212ee83ca127e3c8cf465891ab7216a705f59').never
        @project.should_receive(:build).with('de8251ff97ee194a289832576287d6f8ad74e3d0')
        post_it '/github/push', :payload => payload
      end

      after(:each) { Integrity.config[:build_all_commits] = true }
    end

    describe 'With invalid payload' do
      before(:each) do
        JSON.stub!(:parse).and_raise(JSON::ParserError.new('error message'))
      end

      it 'should rescue any JSON parse error and return a 422 status code' do
        post_it '/github/push'
        @response.status.should == 422
      end

      it 'should rescue any JSON parse error and return the error' do
        post_it '/github/push'
        @response.body.should == 'error message'
      end

      it 'should return error in plain/text' do
        post_it '/github/push'
        @response['Content-Type'].should == 'text/plain'
      end
    end
  end

  describe "POST /:project/builds" do
    it "should build the project" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      mock_project.should_receive(:build)
      post_it "/integrity/builds"
    end

    it "should redirect back to the project" do
      Project.stub!(:first).with(:permalink => "integrity").and_return mock_project
      post_it "/integrity/builds"
      location.should == "/integrity"
    end

    it 'should be 404 if unknown project' do
      Project.stub!(:first).and_return(nil)
      post_it '/integrity/builds'
      status.should == 404
    end

    it "should require authorization" do
    end
  end

  describe 'GET /:project/builds/:build' do
    def do_get
      get_it '/integrity/builds/c86755fd7e37718def0f7a8db6ab68afe25b90bf'
    end

    before(:each) do
      @build = mock_build
      @project = mock_project(:builds => mock('builds', :first => @build))
      Project.stub!(:first).with(:permalink => 'integrity').and_return(@project)
    end

    it 'should be successful' do
      do_get
      status.should == 200
    end

    it 'should load the project from the database using the permalink' do
      Project.should_receive(:first).with(:permalink => 'integrity').and_return(@project)
      do_get
    end

    it 'should be 404 if unknown project' do
      Project.stub!(:first).and_return(nil)
      do_get
      status.should == 404
    end

    it 'should load the build from the database using the commit identifier' do
      @project.builds.should_receive(:first).
        with(:commit_identifier => 'c86755fd7e37718def0f7a8db6ab68afe25b90bf')
      do_get
    end

    it 'should be 404 if unknown build' do
      @project.builds.stub!(:first).and_return(nil)
      do_get
      status.should == 404
    end

    it 'should not display the status of the build' do
      @build.should_not_receive(:human_readable_status).and_return('Build Successful')
      do_get
      body.should_not have_tag('h1', /Build Successful/)
    end

    it 'should colorize the status of the build' do
      @build.should_receive(:status).and_return(:success)
      do_get
      body.should have_tag('#build.success')
    end

    it 'should display the short commit identifier' do
      @build.should_receive(:short_commit_identifier).any_number_of_times.and_return('c86755')
      do_get
      body.should have_tag('h1', /c86755/)
    end

    it 'should display the author of the commit' do
      do_get
      body.should have_tag('.who', /Nicolás Sanguinetti/)
    end

    it 'should display the date of the commit' do
      do_get
      body.should have_tag('.when', /(today|yesterday|on Jul 24th)/)
    end

    it 'should display the full commit identifier' do
      @build.should_receive(:commit_identifier).at_least(:once).and_return('blah blah blah')
      do_get
      body.should have_tag('.what', /blah blah blah/)
    end

    it 'should display the commit message' do
      @build.should_receive(:commit_message).and_return("Add Object#tap for versions of ruby that don't have it")
      do_get
      body.should have_tag('blockquote p', "Add Object#tap for versions of ruby that don't have it")
    end

    it 'should display the output of the build' do
      @build.should_receive(:output).and_return('lots of err')
      do_get
      body.should have_tag('pre.output', /lots of err/)
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

    describe "#current_project" do
      before { @context.stub!(:params).and_return(:project => "integrity") }

      it "should return the project" do
        Project.stub!(:first).with(:permalink => "integrity").and_return(mock_project)
        @context.current_project.should == mock_project
      end

      it "should try to load the project with the permalink provided in the params" do
        Project.should_receive(:first).with(:permalink => "integrity").and_return(mock_project)
        @context.current_project
      end

      it "should raise NotFound if the project cannot be found" do
        Project.stub!(:first).and_return(nil)
        lambda { @context.current_project }.should raise_error(Sinatra::NotFound)
      end
    end

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

    describe '#push_url_for' do
      it 'should receive a project and return its github push url using :base_uri option' do
        Integrity.config.should_receive(:[]).with(:base_uri).and_return('http://foo.org')
        @context.push_url_for(mock_project).should == 'http://foo.org/integrity/push'
      end
    end

    describe '#build_url' do
      before(:each) do
        @build = mock_build(
          :project => mock_project,
          :commit_identifier => 'd32adaa7e42622f5a2f0526985dc010915fab0bf'
        )
      end

      it 'should receive a build and return a link to it' do
        @context.build_url(@build).should == '/integrity/builds/d32adaa7e42622f5a2f0526985dc010915fab0bf'
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
      
      it "should add whatever other fields are passed as a hash" do
        @context.checkbox(:cuack, false, :value => 1).should == { :name => :cuack, :type => "checkbox", :value => 1 }
      end
    end

    describe "#bash_color_codes" do
      it "should replace [0m for a closing span tag" do
        @context.bash_color_codes("<span>something\e[0m").should == '<span>something</span>'
      end

      it "should replace [XXm for a span.colorXX, for XX in 31..37" do
        (31..37).each do |color|
          @context.bash_color_codes("\e[#{color}msomething</span>").should == %Q(<span class="color#{color}">something</span>)
        end
      end
    end

    describe "#authorize" do
      before do
        Integrity.stub!(:config).and_return(
          :use_basic_auth => true,
          :admin_username => "the_user",
          :admin_password => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", # sha1(test)
          :hash_admin_password => true
        )
      end

      it "should hash the password if the settings say so" do
        Digest::SHA1.should_receive(:hexdigest).with("test").and_return("a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
        @context.authorize("the_user", "test")
      end

      it "should not hash the password if the settings do not specify it" do
        Integrity.config[:hash_admin_password] = false
        Digest::SHA1.should_not_receive(:hexdigest)
        @context.authorize("the_user", "test")
      end

      it "should authenticate a user with valid username and password (hashed)" do
        @context.authorize("the_user", "test").should be_true
      end

      it "should not authenticate a user with an invalid username" do
        @context.authorize("1337 h4x0r", "test").should be_false # hah, not so leet, ah?
      end

      it "should authenticate regardless of username if use_basic_auth is false" do
        Integrity.config[:use_basic_auth] = false
        @context.authorize('foo', 'bar').should be_true
      end
    end

    describe "#pretty_date" do
      before do
        @yesterday  = Time.mktime(2008, 07, 24, 17, 18)
        @today      = Time.mktime(2008, 07, 25, 17, 18)
        @a_week_ago = Time.mktime(2008, 07, 17, 17, 18)
        Time.stub!(:now).and_return(@today)
      end

      it { @context.pretty_date(@today).should == "today" }

      it { @context.pretty_date(@yesterday).should == "yesterday" }

      it { @context.pretty_date(@a_week_ago).should == "on Jul 17th"}
    end
  end
end
