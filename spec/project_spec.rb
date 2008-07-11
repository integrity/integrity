require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Project do
  before(:each) do
    @project = Integrity::Project.new
  end

  it 'should not be valid' do
    @project.should_not be_valid
  end
  
  it "needs a name, an uri, a branch and a command to be valid" do
    @project.attributes = { :name => "Integrity", :uri => "git://github.com/foca/integrity.git" }
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

  describe 'When building it' do
    before(:each) do
      @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
      @project = Integrity::Project.new(
        :uri      => @uri,
        :branch   => 'production',
        :command  => 'rake spec'
      )
      @builder = mock('Builder', :build => true)
      Integrity::Builder.stub!(:new).and_return(@builder)
    end

    it 'should instantiate a new Builder with uri, branch and command' do
      Integrity::Builder.should_receive(:new).
        with(@uri, 'production', 'rake spec').and_return(@builder)
      @project.build
    end

    it 'should call the builder to build it' do
      @builder.should_receive(:build)
      @project.build
    end
  end
end
