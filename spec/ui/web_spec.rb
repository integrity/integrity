require File.dirname(__FILE__) + '/../spec_helper'

require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'

describe 'Web UI using Sinatra' do
  require File.dirname(__FILE__) + '/../../lib/integrity/ui/web'

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
      
      it "tell you that you have no projects" do
        get_it "/"
        @response.body.should =~ /None yet, huh?/
      end
    end
    
    describe "with available projects" do
      before(:each) do
        @project_1 = stub("Project", :name => "The 1st Project", :permalink => "the_1st_project")
        @project_2 = stub("Project", :name => "The 2nd Project", :permalink => "the_2nd_project")
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
        @response.body.should =~ %r(<a href='/the_1st_project'>The 1st Project</a>)
        @response.body.should =~ %r(<a href='/the_2nd_project'>The 2nd Project</a>)
      end
    end
  end
end
