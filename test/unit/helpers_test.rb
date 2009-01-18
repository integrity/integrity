require File.dirname(__FILE__) + "/../helpers"

class BrowsePublicProjectsTest < Test::Unit::TestCase
  include Helpers

  test "#pretty_date" do
    pretty_date(Time.now).should == "today"
    pretty_date(Time.mktime(Time.now.year, Time.now.month, Time.now.day-1)).should == "yesterday"

    pretty_date(Time.mktime(1995, 12, 01)).should == "on Dec 01st"
    pretty_date(Time.mktime(1995, 12, 21)).should == "on Dec 21st"
    pretty_date(Time.mktime(1995, 12, 31)).should == "on Dec 31st"

    pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"
    pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"

    pretty_date(Time.mktime(1995, 12, 03)).should == "on Dec 03rd"
    pretty_date(Time.mktime(1995, 12, 23)).should == "on Dec 23rd"

    pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
  end
end
