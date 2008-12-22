require File.dirname(__FILE__) + '/test_helper'

describe "Build" do
  Build = Integrity::Build unless defined?(Build)
  
  before(:each) do
    RR.reset
    setup_and_reset_database!
  end
  
  specify "fixture is valid and can be saved" do
    lambda do
      Build.generate.tap do |build|
        build.should be_valid
        build.save
      end
    end.should change(Build, :count).by(1)
  end
  
  describe "Properties" do
    before(:each) do
      @build = Build.generate(:commit_identifier => "658ba96cb0235e82ee720510c049883955200fa9")
    end
    
    it "captures the build's STDOUT/STDERR" do
      @build.output.should_not be_blank
    end
    
    it "knows if it failed or not" do
      @build.successful = true
      @build.should be_successful
      @build.successful = false
      @build.should be_failed
    end
    
    it "knows it's status" do
      @build.successful = true
      @build.status.should be(:success)
      @build.successful = false
      @build.status.should be(:failed)
    end
    
    it "has an human readable status" do
      Build.gen(:successful => true).human_readable_status.should == "Build Successful"
      Build.gen(:successful => false).human_readable_status.should == "Build Failed"
    end

    it "has a commit identifier" do
      @build.commit_identifier.should be("658ba96cb0235e82ee720510c049883955200fa9")
    end

    it "has a short commit identifier" do
      @build.short_commit_identifier.should == "658ba96"
      Build.gen(:commit_identifier => "402").short_commit_identifier.should == "402"
    end
    
    it "has a commit author" do
      build = Build.gen(:commit_metadata => { :author => "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>" })
      build.commit_author.name.should == "Nicolás Sanguinetti"
      build.commit_author.email.should == "contacto@nicolassanguinetti.info"
      build.commit_author.full.should == "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>"
    end
    
    it "has a commit message" do
      build = Build.gen(:commit_metadata => { :message => "This commit rocks" })
      build.commit_message.should == "This commit rocks"
    end
    
    it "has a commit date" do
      build = Build.gen(:commit_metadata => { :date => Time.utc(2008, 10, 12, 14, 18, 20) })
      build.commited_at.to_s.should == "Sun Oct 12 14:18:20 UTC 2008"
    end
  end
end
