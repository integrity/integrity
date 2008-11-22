require File.dirname(__FILE__) + '/../spec_helper'

describe Integrity::SCM::Git do
  before do
    Integrity::SCM::Git.class_eval { public :fetch_code, :clone, :checkout, :pull, :local_branches, :cloned?, :on_branch? }
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

  it "should give the name of the SCM being used" do
    @git.name.should == "Git"
  end

  specify "#log should delegate to Integrity#log with 'Git' as progname" do
    message = lambda { "message" }
    Integrity.logger.should_receive(:info).with("Git") { message }
    @git.send(:log, "message")
  end

  describe "Determining the state of the code for this project" do
    it "should know if a project has been cloned or not by looking at the directories" do
      File.stub!(:directory?).with("/var/integrity/exports/foca-integrity/.git").and_return(true)
      @git.should be_cloned
    end

    it "should know if a checkout is on the current branch by asking git the branch" do
      @git.should_receive(:`).with("cd /var/integrity/exports/foca-integrity && git symbolic-ref HEAD").and_return("refs/heads/master\n")
      @git.should be_on_branch
    end

    it "should tell you if it's not in the desired branch" do
      @git.should_receive(:`).with("cd /var/integrity/exports/foca-integrity && git symbolic-ref HEAD").and_return("refs/heads/other_branch\n")
      @git.should_not be_on_branch
    end
  end

  describe "Logging of operations" do
    before do
      @git.stub!(:`)
      Integrity.stub!(:logger).and_return(mock("logger", :info => ""))
    end

    it "should log clone" do
      @git.should_receive(:log).
        with("Cloning git://github.com/foca/integrity.git to /var/integrity/exports/foca-integrity")
      @git.clone
    end

    it "should log checkout" do
      @git.should_receive(:log).with("Checking-out HEAD")
      @git.checkout('HEAD')
    end

    it "should log pull" do
      @git.should_receive(:log).with("Pull-ing in /var/integrity/exports/foca-integrity")
      @git.pull
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
  
  describe 'Running code in a specific context using #with_revision' do
    before(:each) do
      @block = lambda { 'lambda the ultimate' }
      @git.stub!(:fetch_code)
      @git.stub!(:checkout)
    end

    it "should fetch the latest code" do
      @git.should_receive(:fetch_code)
      @git.with_revision('HEAD', &@block)
    end

    it 'should checkout the given revision' do
      @git.should_receive(:checkout).with('4d0cfafd569ef60d0c578bf8a9d51f9582612f03')
      @git.with_revision('4d0cfafd569ef60d0c578bf8a9d51f9582612f03', &@block)
    end
  end

  describe "Getting information about a commit" do
    before do
      @serialized = ["---",
                     ':author: Nicolás Sanguinetti <contacto@nicolassanguinetti.info>',
                     ':message: >-',
                     '  A beautiful commit'] * "\n"
      @git.stub!(:`).and_return @serialized
    end

    it "should ask git for the commit" do
      @git.should_receive(:`).with(/^cd \/var\/integrity\/exports\/foca-integrity && git show -s.*HEAD/).and_return(@serialized)
      @git.commit_metadata("HEAD")
    end

    it "should ask YAML to interpret the serialized info" do
      YAML.should_receive(:load).with(@serialized).and_return({})
      @git.commit_metadata("HEAD")
    end

    it "should not blow up if the author name has a colon in the middle" do
      @serialized.gsub! 'Nicolás Sanguinetti', 'the:dude'
      lambda { @git.commit_metadata("HEAD") }.should_not raise_error
    end

    it "should not blow up if the commit message has a colon in the middle" do
      @serialized.gsub! 'A beautiful commit', %Q(Beautiful: "A commit" with\n  newlines and 'lots of quoting')
      lambda { @git.commit_metadata("HEAD") }.should_not raise_error
    end

    it "should have yaml chomp the commit message (and remove any intermediate newlines)" do
      @serialized.gsub! 'A beautiful commit', %Q(Beautiful: "A commit" with\n  newlines and 'lots of quoting')
      @git.commit_metadata("HEAD")[:message].should == %Q(Beautiful: "A commit" with newlines and 'lots of quoting')
    end

    it "should return a hash with all the relevant information" do
      @git.commit_metadata("HEAD").should == {
        :author => "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>",
        :message => "A beautiful commit"
      }
    end
  end

  describe "Listing the local branches" do
    def branches
      ["* master",
       "  other",
       "  yet_another"] * "\n"
    end

    it "should return an array of branch names" do
      @git.stub!(:`).with("cd /var/integrity/exports/foca-integrity && git branch").and_return(branches)
      @git.local_branches.should == ["master", "other", "yet_another"]
    end
  end

  describe "Doing all the low-level operations on the repo" do
    it "should pass the uri and expected working directory to git-clone when cloning" do
      @git.should_receive(:`).with("git clone git://github.com/foca/integrity.git /var/integrity/exports/foca-integrity")
      @git.clone
    end

    it "should switch dirs to the repo's and call git-pull when pulling" do
      @git.should_receive(:`).with("cd /var/integrity/exports/foca-integrity && git pull")
      @git.pull
    end

    describe "(checking out code)" do
      it "should check out the branch locally if it's already available" do
        @git.stub!(:local_branches).and_return(["master"])
        @git.should_receive(:`).with("cd /var/integrity/exports/foca-integrity && git checkout master")
        @git.checkout
      end

      it "should create a new branch that tracks an external branch if the branch isn't local" do
        @git.stub!(:local_branches).and_return(["master"])
        @git.stub!(:branch).and_return("redux")
        @git.should_receive(:`).with("cd /var/integrity/exports/foca-integrity && git checkout -b redux origin/redux")
        @git.checkout
      end

      it 'should checkout the given commit' do
        @git.should_receive(:`).with('cd /var/integrity/exports/foca-integrity && git checkout 7e4f36231776ea4401b6e385df5f43c11633d59f')
        @git.checkout('7e4f36231776ea4401b6e385df5f43c11633d59f')
      end

      it 'should checkout the given treeish' do
        @git.should_receive(:`).with('cd /var/integrity/exports/foca-integrity && git checkout origin/HEAD')
        @git.checkout('origin/HEAD')
      end
    end
    
    describe "Getting the commit identifier from a given treeish" do
      it "should ask git about it" do
        @git.should_receive(:`).with('cd /var/integrity/exports/foca-integrity && git show -s --pretty=format:%H 7e4f3623').and_return("7e4f36231776ea4401b6e385df5f43c11633d59f\n")
        @git.commit_identifier('7e4f3623')
      end
    end
  end
  
  describe "mapping a repo url to a working tree path (from the git url)" do
    it "should delegate to Git::URI" do
      Integrity::SCM::Git::URI.should_receive(:new).with("git://foo.git").and_return(stub("blah", :working_tree_path => nil))
      Integrity::SCM::Git.working_tree_path("git://foo.git")
    end
  end  
end
