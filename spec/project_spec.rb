require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Project do
  before { @project = Integrity::Project.new }

  def valid_attributes(attributes={})
    { :name => "Integrity",
      :uri => "git://github.com/foca/integrity.git",
      :permalink => "integrity" }.merge(attributes)
  end

  it 'should not be valid' do
    @project.should_not be_valid
  end
  
  it "needs a name, a permalink, an uri, a branch and a command to be valid" do
    @project.attributes = valid_attributes
    @project.should be_valid
  end

  it 'should have a name' do
    @project.name = 'Integrity'
    @project.name.should == 'Integrity'
  end

  it 'should validates name uniqueness' do
    Integrity::Project.create(valid_attributes(:name => 'foobar'))
    p = Integrity::Project.create(valid_attributes(:name => 'foobar'))
    p.errors.on(:name).should include('Name is already taken')
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
  
  describe "Ensuring the public/private status" do
    before do
      @project = Integrity::Project.new(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
    end
    
    it "should be public after saving" do
      @project.public = true
      @project.save
      @project.reload.should be_public
    end
    
    it "should not be public if set to false" do
      @project.public = false
      @project.save
      @project.reload.should_not be_public
    end
    
    it "should be public if set to any non-false value" do
      @project.public = "on"
      @project.save
      @project.reload.should be_public
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

    it 'should tell the builder to build the head if no commit id is passed' do
      @builder.should_receive(:build).with("HEAD")
      @project.build
    end
    
    it "should tell the builder to build a specific commit if an id is passed" do
      @builder.should_receive(:build).with('6eba34d94b74fe68b96e35450fadf241113e44fc')
      @project.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
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
    before do
      @project.update_attributes(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
      5.times do
        @project.builds.create(
          :commit_identifier => 'commit sha1',
          :commit_metadata => {:author => "someguy", :date => "yesterday"},
          :output => "o"
        )
      end
    end
    
    it "should find the last build by ordering chronologically" do
      @project.builds.should_receive(:last)
      @project.last_build
    end
    
    it "should have 4 previous builds" do
      @project.should have(4).previous_builds
    end
    
    it "should return an empty array if it has only one build" do
      @project.builds.to_a[1..-1].map {|b| b.destroy }
      @project.previous_builds.should be_empty
    end
    
    it "should return an empty array if there are no builds" do
      @project.builds.map {|b| b.destroy }
      @project.previous_builds.should be_empty
    end
  end
  
  describe "Getting destroyed" do
    before do
      @builder = mock("Builder", :delete_code => true)
      Integrity::Builder.stub!(:new).with(@project).and_return(@builder)
      @project.update_attributes(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
      @project.builds.stub!(:destroy!)
    end
    
    it "should delete all the project builds" do
      @project.builds.should_receive(:destroy!)
      @project.destroy
    end
    
    it "should tell the builder to delete the code for this project" do
      @builder.should_receive(:delete_code).and_return(true)
      @project.destroy
    end
  end
end
