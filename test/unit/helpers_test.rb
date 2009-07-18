require File.dirname(__FILE__) + "/../helpers"

class HelpersTest < Test::Unit::TestCase
  setup do
    @h = Module.new { extend Integrity::Helpers }
  end

  test "#pretty_date" do
    @h.pretty_date(Time.now).should == "today"
    @h.pretty_date(Time.new - 86400).should == "yesterday"

    @h.pretty_date(Time.mktime(1995, 12, 01)).should == "on Dec 1st"
    @h.pretty_date(Time.mktime(1995, 12, 21)).should == "on Dec 21st"
    @h.pretty_date(Time.mktime(1995, 12, 31)).should == "on Dec 31st"

    @h.pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"
    @h.pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"

    @h.pretty_date(Time.mktime(1995, 12, 03)).should == "on Dec 3rd"
    @h.pretty_date(Time.mktime(1995, 12, 23)).should == "on Dec 23rd"

    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
  end
end
