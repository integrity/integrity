require File.dirname(__FILE__) + "/../spec_helper"

describe Time, "strftime with %o for day ordinals (st, nd, rd and th)" do
  def ordinal_for_day(n)
    Time.mktime(2008, 07, n).strftime("%o")
  end

  it "should return st for 1, 21 and 31" do
    [1, 21, 31].each {|day| ordinal_for_day(day).should == "st" }
  end

  it "should return nd for 2 and 22" do
    [2, 22].each {|day| ordinal_for_day(day).should == "nd" }
  end

  it "should return rd for 3 and 23" do
    [3, 23].each {|day| ordinal_for_day(day).should == "rd" }
  end

  it "should return th for the rest" do
    (04..20).each {|day| ordinal_for_day(day).should == "th" }
    (24..30).each {|day| ordinal_for_day(day).should == "th" }
  end
end
