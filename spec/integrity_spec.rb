require File.dirname(__FILE__) + "/spec_helper"

describe Integrity do
  describe "#root" do
    it "should point to the directory where all integrity files are located" do
      Integrity.root.should == File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end
  end
end