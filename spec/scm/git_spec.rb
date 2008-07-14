require File.dirname(__FILE__) + '/../spec_helper'

describe Integrity::SCM::Git do
  def mock_repo
    @repo ||= mock("ruby-git repo")
  end
  
  before do
    Integrity::SCM::Git.class_eval { public :repo, :fetch_code, :chdir }
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
  
  describe "Connecting to the repo" do
    it "should try to open a local copy of the repository" do
      Integrity::RubyGit.should_receive(:open).with("/var/integrity/exports/foca-integrity").and_return(mock_repo)
      @git.repo
    end
    
    it "should try to clone the repo if there's no local copy" do
      Integrity::RubyGit.should_receive(:open).and_raise(ArgumentError)
      Integrity::RubyGit.should_receive(:clone).with(
        "git://github.com/foca/integrity.git", 
        "/var/integrity/exports/foca-integrity"
      )
      @git.repo
    end
    
    it "should memoize the repository instead of trying to open it twice" do
      Integrity::RubyGit.should_receive(:open).exactly(:once).and_return(mock_repo)
      2.times { @git.repo }
    end
  end
  
  describe "Fetching the code from the repo" do
    before do
      @git.stub!(:repo).and_return(mock_repo)
      mock_repo.stub!(:branch).and_return stub("branch", :name => "master")
      mock_repo.stub!(:checkout).with("production")
      mock_repo.stub!(:pull)
    end
    
    it "should checkout the branch if it's not on it" do
      mock_repo.stub!(:branch).and_return stub("branch", :name => "blah")
      mock_repo.should_receive(:checkout).with("master")
      @git.fetch_code
    end
    
    it "should not checkout the branch if it's already on it" do
      mock_repo.should_not_receive(:checkout).with("master")
      @git.fetch_code
    end
    
    it "should pull the code" do
      mock_repo.should_receive(:pull)
      @git.fetch_code
    end
  end
  
  describe "Changing the current directory to that of the checkout" do
    it "should let ruby-git handle it by forwarding the call" do
      block = lambda { "cuack" }
      @git.stub!(:repo).and_return(mock_repo)
      mock_repo.should_receive(:chdir).with(&block).and_yield
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
  
  describe "Getting information about the HEAD" do
    before do
      @head = mock("commit", 
        :sha => "HEAD", # what do I do to get the actual SHA?
        :message => "blah", 
        :author => mock("author", 
          :name => "John Doe", 
          :email => "john@example.com"
        )
      )
      mock_repo.stub!(:object).with("HEAD").and_return @head
      @git.stub!(:repo).and_return(mock_repo)
    end
    
    it "should get the commit's message" do
      @git.head[:message].should == "blah"
    end
    
    it "should get the commit's author, nicely formatted" do
      @git.head[:author].should == "John Doe <john@example.com>"
    end
    
    it "should get the commit's sha" do
      pending "find out how to get the actual sha instead of 'HEAD'"
      @git.head[:sha].should == "12a3f45b"
    end
    
    it "should memoize the commit's information" do
      mock_repo.should_receive(:object).with("HEAD").exactly(:once).and_return(@head)
      2.times { @git.head }
    end
  end
  
  describe "The namespacing hack to get ruby-git to work with SCM::Git" do
    it "should forward calls from RubyGit.open to Git.open" do
      Git.should_receive(:open).with("doesnt", "matter")
      Integrity::RubyGit.open("doesnt", "matter")
    end
    
    it "should forward calls from RubyGit.clone to Git.clone" do
      Git.should_receive(:clone).with("doesnt", "matter")
      Integrity::RubyGit.clone("doesnt", "matter")
    end
  end
end
