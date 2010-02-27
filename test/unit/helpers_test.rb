require "helper"

class HelpersTest < IntegrityTest
  test "pretty_date" do
    h = Module.new { extend Integrity::Helpers }

    assert_equal "today",       h.pretty_date(Time.now)
    assert_equal "yesterday",   h.pretty_date(Time.new - 86400)

    assert_equal "on Dec 1st",  h.pretty_date(Time.mktime(1995, 12, 01))
    assert_equal "on Dec 21st", h.pretty_date(Time.mktime(1995, 12, 21))
    assert_equal "on Dec 31st", h.pretty_date(Time.mktime(1995, 12, 31))

    assert_equal "on Dec 22nd", h.pretty_date(Time.mktime(1995, 12, 22))
    assert_equal "on Dec 3rd",  h.pretty_date(Time.mktime(1995, 12, 03))
    assert_equal "on Dec 23rd", h.pretty_date(Time.mktime(1995, 12, 23))
    assert_equal "on Dec 15th", h.pretty_date(Time.mktime(1995, 12, 15))
  end
end
