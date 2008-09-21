require File.dirname(__FILE__) + "/../spec_helper"

describe Object, "tap" do
  before do
    @object = Object.new
  end

  it "should yield the receiver" do
    @object.tap {|o| o.should == @object }
  end

  it "should return the receiver, no matter the block result" do
    @object.tap { "secondary effects" }.should == @object
  end
end
