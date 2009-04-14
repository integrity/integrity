require File.dirname(__FILE__) + "/../helpers/acceptance"
require "helpers/acceptance/email_notifier"
require "helpers/acceptance/textfile_notifier"

require "integrity/notifier/test"

class NotifierTestTest < Test::Unit::TestCase
  include Integrity::Notifier::Test

  setup do
    @notifier = Integrity::Notifier::Textfile
    @config   = {"file" => "/tmp/integrity.txt"}
    @build    = Integrity::Build.gen(:successful)

    FileUtils.rm @config["file"] if File.exists?(@config["file"])
  end

  def notifier
    "Textfile"
  end

  test "it provides a formulary to configure options" do
    assert_form_have_option("file", @config["file"])
  end

  test "it sends notification" do
    @notifier.notify_of_build(@build, @config)

    notification = File.read(@config["file"])

    assert notification.start_with?("===")
    assert notification.include?(@build.commit.identifier)
    assert notification.include?("successful")
  end
end
