require File.dirname(__FILE__) + "/../helpers"
require "helpers/acceptance/email_notifier"

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
    commit = Integrity::Commit.gen(:build => Build.gen(:successful))

    assert notification(commit).include?(commit.identifier)
    assert notification_failed.include?("failed")
    assert notification_successful.include?("was successful")
  end
end
