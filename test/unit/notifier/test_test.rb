require File.dirname(__FILE__) + "/../../helpers"
require "helpers/acceptance/textfile_notifier"

require "integrity/notifier/test"

class NotifierTestTest < Test::Unit::TestCase
  include Integrity::Notifier::Test

  before(:each) do
    # Because we unset every notifier in global setup
    load "helpers/acceptance/textfile_notifier.rb"
  end

  def notifier
    "Textfile"
  end

  test "it provides a formulary to configure options" do
    assert_form_have_option("file")
  end

  test "it sends notification" do
    assert notification.include?(commit.message)
  end
end
