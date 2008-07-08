require File.dirname(__FILE__) + "/../spec_helper"

describe String, "/" do
  it "should join two strings as a path" do
    ("foo" / "bar").should == "foo/bar"
  end
  
  it "should ignore leading slashes in argument" do
    ("foo" / "/bar").should == "foo/bar"
  end
  
  it "should ignore trailing slashes in the receiver" do
    ("foo/" / "bar").should == "foo/bar"
  end
  
  it "should not ignore trailing slashes in the argument" do
    ("foo" / "bar/").should == "foo/bar/"
  end
  
  it "should not add duplicate slashes" do
    ("foo/" / "/bar").should == "foo/bar"
  end
end