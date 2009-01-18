require File.dirname(__FILE__) + '/../helpers'

class CommitTest < Test::Unit::TestCase
  before(:each) do
    RR.reset
    setup_and_reset_database!
  end

  specify "fixture is valid and can be saved" do
    lambda do
      commit = Commit.gen
      commit.save

      commit.should be_valid
    end.should change(Commit, :count).by(1)
  end

  describe "Properties" do
    before(:each) do
      @commit = Commit.generate(:identifier => "658ba96cb0235e82ee720510c049883955200fa9", 
                                :author => "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>")
    end
    
    it "has a commit identifier" do
      @commit.identifier.should be("658ba96cb0235e82ee720510c049883955200fa9")
    end

    it "has a short commit identifier" do
      @commit.short_identifier.should == "658ba96"

      @commit.identifier = "402"
      @commit.short_identifier.should == "402"
    end
    
   it "has a commit author" do
     commit = Commit.gen(:author => "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>")
     commit.author.name.should == "Nicolás Sanguinetti"
     commit.author.email.should == "contacto@nicolassanguinetti.info"
     commit.author.full.should == "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>"
   end

    it "has a commit message" do
      commit = Commit.gen(:message => "This commit rocks")
      commit.message.should == "This commit rocks"
    end

    it "has a commit date" do
      commit = Commit.gen(:committed_at => Time.utc(2008, 10, 12, 14, 18, 20))
      commit.committed_at.to_s.should == "2008-10-12T14:18:20+00:00"
    end

    it "has a human readable status" do
      commit = Commit.gen(:successful, :identifier => "658ba96cb0235e82ee720510c049883955200fa9")
      commit.human_readable_status.should be("Built 658ba96 successfully")
      
      commit = Commit.gen(:failed, :identifier => "658ba96cb0235e82ee720510c049883955200fa9")
      commit.human_readable_status.should be("Built 658ba96 and failed")
      
      commit = Commit.gen(:pending, :identifier => "658ba96cb0235e82ee720510c049883955200fa9")
      commit.human_readable_status.should be("658ba96 hasn't been built yet")
    end
  end
  
  describe "Queueing a build" do
    before(:each) do
      @commit = Commit.gen
      stub.instance_of(ProjectBuilder).build(@commit)
    end
    
    it "creates an empty Build" do
      @commit.build.should be_nil
      @commit.queue_build
      @commit.build.should_not be_nil
    end
    
    it "ensures the build is saved" do
      @commit.build.should be_nil
      @commit.queue_build
      
      commit = Commit.first(:identifier => @commit.identifier)
      commit.build.should_not be_nil
    end
  end
end