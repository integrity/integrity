require File.dirname(__FILE__) + '/../spec_helper'

describe Integrity::SCM::Git do
  before do
    Integrity::SCM::Git.class_eval { public :fetch_code, :chdir, :clone, :checkout, :pull, :commit_info, :cloned?, :on_branch? }
    @git = Integrity::SCM::Git.new("git://github.com/foca/integrity.git", "master", "/var/integrity/exports/foca-integrity")
  end
  
  it "should point to the correct repository" do
    @git.uri.should == "git://github.com/foca/integrity.git"
  end
  
  it "should track the correct branch" do
    @git.branch.should == "master"
  end
  
  it "should point to the correct working directory" do
    @git.working_directory.should == "/var/integrity/exports/foca-integrity"
  end
  
  describe "Determining the state of the code for this project" do
    it "should know if a project has been cloned or not by looking at the directories" do
      File.stub!(:directory?).with("/var/integrity/exports/foca-integrity/.git").and_return(true)
      @git.should be_cloned
    end
    
    it "should know if a checkout is on the current branch by asking git the branch" do
      @git.stub!(:chdir).and_yield
      @git.should_receive(:`).with("git symbolic-ref HEAD").and_return("refs/heads/master\n")
      @git.should be_on_branch
    end
    
    it "should tell you if it's not in the desired branch" do
      @git.stub!(:chdir).and_yield
      @git.should_receive(:`).with("git symbolic-ref HEAD").and_return("refs/heads/other_branch\n")
      @git.should_not be_on_branch
    end
  end
  
  describe "Fetching the code from the repo" do
    before do
      @git.stub!(:on_branch?).and_return(true)
      @git.stub!(:cloned?).and_return(true)
      @git.stub!(:pull)
    end
    
    it "should clone the repository if it hasn't already" do
      @git.stub!(:cloned?).and_return(false)
      @git.should_receive(:clone)
      @git.fetch_code
    end
    
    it "should not clone the repository if it has done so before" do
      @git.stub!(:cloned?).and_return(true)
      @git.should_not_receive(:clone)
      @git.fetch_code
    end
    
    it "should checkout the branch if it's not on it" do
      @git.stub!(:on_branch?).and_return(false)
      @git.should_receive(:checkout)
      @git.fetch_code
    end
    
    it "should not checkout the branch if it's already on it" do
      @git.stub!(:on_branch?).and_return(true)
      @git.should_not_receive(:checkout)
      @git.fetch_code
    end
    
    it "should pull the code" do
      @git.should_receive(:pull)
      @git.fetch_code
    end
  end
  
  describe "Changing the current directory to that of the checkout" do
    it "should let ruby-git handle it by forwarding the call" do
      block = lambda { "cuack" }
      Dir.should_receive(:chdir).with("/var/integrity/exports/foca-integrity", &block)
      @git.chdir(&block)
    end
  end

  describe "Running code in the context of the most recent checkout" do
    before do
      @block = lambda { "cuack" }
      @git.stub!(:fetch_code)
      @git.stub!(:chdir).with(&@block)
    end
    
    it "should ensure it has the latest code" do
      @git.should_receive(:fetch_code)
      @git.with_latest_code(&@block)
    end
    
    it "should run the block in the working copy directory" do
      @git.should_receive(:chdir).with(&@block).and_yield
      @git.with_latest_code(&@block)
    end
  end
  
  describe "Getting information about a commit" do
    before do
      @serialized = ["---",
                     ":identifier: 7e4f36231776ea4401b6e385df5f43c11633d59f",
                     ":author: Nicolás Sanguinetti <contacto@nicolassanguinetti.info>",
                     ":message: A beautiful commit"] * "\n"
      @git.stub!(:chdir).and_yield
      @git.stub!(:`).and_return @serialized
    end
    
    it "should switch to the project's directory" do
      @git.should_receive(:chdir).and_yield
      @git.commit_info("HEAD")
    end
    
    it "should ask git for the commit" do
      @git.should_receive(:`).with(/^git show -s.*HEAD/).and_return(@serialized)
      @git.commit_info("HEAD")
    end
    
    it "should ask YAML to interpret the serialized info" do
      YAML.should_receive(:load).with(@serialized).and_return({})
      @git.commit_info("HEAD")
    end
    
    it "should return a hash with all the relevant information" do
      @git.commit_info("HEAD").should == {
        :identifier => "7e4f36231776ea4401b6e385df5f43c11633d59f",
        :author => "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>",
        :message => "A beautiful commit"
      }
    end
  end
  
  describe "Getting the HEAD of the repo" do
    it "should pass down the request to #commit_info" do
      @git.should_receive(:commit_info).with("HEAD")
      @git.head
    end
  end
  
  describe "Doing all the low-level operations on the repo" do
    it "should pass the uri and expected working directory to git-clone when cloning" do
      @git.should_receive(:system).with("git clone git://github.com/foca/integrity.git /var/integrity/exports/foca-integrity")
      @git.clone
    end
    
    it "should change dirs to the repo's and checkout the appropiate branch via git-checkout" do
      @git.should_receive(:chdir).and_yield
      @git.should_receive(:system).with("git checkout -b master origin/master")
      @git.checkout
    end
    
    it "should check out a branch that has already been initialized locally without failing" do
      pending "it only works the first time you change the branch, need to fix"
    end
    
    it "should switch dirs to the repo's and call git-pull when pulling" do
      @git.should_receive(:chdir).and_yield
      @git.should_receive(:system).with("git pull")
      @git.pull
    end
  end
end
