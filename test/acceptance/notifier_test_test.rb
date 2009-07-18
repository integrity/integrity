require File.dirname(__FILE__) + "/../helpers/acceptance"
require "helpers/acceptance/email_notifier"
require "helpers/acceptance/textfile_notifier"

require "integrity/notifier/test"

class NotifierTestTest < Test::Unit::TestCase
  include Integrity::Notifier::Test

  setup do
    Integrity.config[:base_uri] = "http://example.org/"

    @notifier = Integrity::Notifier::Textfile
    @config   = {"file" => "/tmp/integrity.txt"}

    FileUtils.rm @config["file"] if File.exists?(@config["file"])
  end

  def notifier
    "Textfile"
  end

  test "it provides a formulary to configure options" do
    assert provides_option?("file")
    assert provides_option?("file", @config["file"])
  end

  test "it sends notification" do
    build = build(:successful)

    @notifier.notify_of_build(build, @config)

    notification = File.read(@config["file"])

    assert notification.start_with?("===")
    assert notification.include?(build.commit.identifier)
    assert notification.include?("successful")
  end
end
