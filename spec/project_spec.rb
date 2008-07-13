require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Project do
  before(:each) do
    @project = Integrity::Project.new
  end

  it 'should not be valid' do
    @project.should_not be_valid
  end
  
  it "needs a name, a permalink, an uri, a branch and a command to be valid" do
    @project.attributes = { :name => "Integrity", :uri => "git://github.com/foca/integrity.git", :permalink => "integrity" }
    @project.should be_valid
  end

  it 'should have a name' do
    @project.name = 'Integrity'
    @project.name.should == 'Integrity'
  end

  it 'should have a repository URI' do
    @project.uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @project.uri.should be_an_instance_of(Addressable::URI)
  end
  
  it "should have a default project branch" do
    @project.branch.should == "master"
  end

  it 'should have a project branch' do
    @project.branch = 'development'
    @project.branch.should == 'development'
  end

  it 'should have a default build command' do
    @project.command.should == 'rake'
  end

  it 'should have a build command' do
    @project.command = 'rake spec'
    @project.command.should == 'rake spec'
  end

  it 'should have a default visibility of public' do
    @project.should be_public
  end

  it 'should have a visibility' do
    @project.public = false
    @project.should_not be_public
  end
  
  describe "Setting the permalink" do
    before do
      @project = Integrity::Project.new(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
    end
    
    it "should set the permalink before saving" do
      @project.permalink.should be_nil
    end
    
    it "should set the permalink on save" do
      @project.save
      @project.permalink.should == "integrity"
    end
    
    it "should update the permalink if the name changes" do
      @project.name = "Foca's Awesome Project & Strange Name"
      @project.save
      @project.permalink.should == "focas-awesome-project-and-strange-name"
    end
  end

  describe 'When building it' do
    before(:each) do
      @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
      @project = Integrity::Project.new(
        :uri      => @uri,
        :branch   => 'production',
        :command  => 'rake spec'
      )
      @build = Integrity::Build.new(:output => "blah", :error => "blah", :status => true, :commit => {
        :author => 'Simon Rozet <simon@rozet.name>',
        :identifier => '712041aa093e4fb0a2cb1886db49d88d78605396',
        :message    => 'started build model'
      })
      @builder = mock('Builder', :build => @build)
      Integrity::Builder.stub!(:new).and_return(@builder)
    end

    it 'should instantiate a new Builder with uri, branch and command' do
      Integrity::Builder.should_receive(:new).
        with(@uri, 'production', 'rake spec').and_return(@builder)
      @project.build
    end

    it 'should call the builder to build it' do
      @builder.should_receive(:build).and_return(@build)
      @project.build
    end
    
    it "should set itself as the build's project" do
      @project.build
      @build.project.should == @project
    end
    
    it "should save the build to the database" do
      @build.should_receive(:save)
      @project.build
    end
  end
end
