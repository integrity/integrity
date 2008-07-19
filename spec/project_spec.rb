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
    
    it "should not end up having dashes at the end" do
      @project.name = "Ends in symbols!@%^"
      @project.save
      @project.permalink.should == "ends-in-symbols"
    end
  end

  describe 'When building it' do
    before(:each) do
      @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
      @project = Integrity::Project.new(:uri => @uri, :branch  => 'production', :command  => 'rake spec')
      @builder = mock('Builder', :build => true)
      Integrity::Builder.stub!(:new).and_return(@builder)
    end
    
    it "should not build if it's already building" do
      @project.stub!(:building?).and_return(true)
      Integrity::Builder.should_not_receive(:new)
      @project.build
    end

    it 'should instantiate a new Builder and pass itself to it' do
      Integrity::Builder.should_receive(:new).with(@project).and_return(@builder)
      @project.build
    end

    it 'should tell the builder to ... build!' do
      @builder.should_receive(:build)
      @project.build
    end
    
    it "should set 'building?' to true while building" do
      @builder.should_receive(:build) do
        @project.should be_building
      end
      @project.build
    end
    
    it "should set 'building?' to false after a build" do
      @project.build
      @project.should_not be_building
    end
    
    it "should ensure 'building?' is false even if the build raises an exception" do
      lambda {
        @builder.stub!(:build).and_raise(RuntimeError)
        @project.build
        @project.should_not be_building
      }.should raise_error(RuntimeError)      
    end
  end
  
  describe "When searching for its builds" do
    it "should find the last build by ordering chronologically" do
      @project.builds.should_receive(:first).with hash_including(:order => [:created_at.desc])
      @project.last_build
    end
    
    it "should find the 'tail' of builds by searching for all the builds, with offset 1" do
      pending "why doesn't this work?"
      @project.builds.stub!(:count).and_return(5)
      @project.builds.should_receive(:all).with hash_including(:offset => 1, :limit => 4)
      @project.previous_builds
    end
    
    it "should find the 'tail' of builds ordering them chronologically" do
      pending "why doesn't this work?"
      @project.builds.should_receive(:all).with hash_including(:order => [:created_at.desc])
      @project.previous_builds
    end
  end
end
