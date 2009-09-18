require File.dirname(__FILE__) + "/../helpers"

class IntegrityTest < Test::Unit::TestCase
  setup do
    Integrity.instance_variable_set(:@config, nil)
    stub(DataMapper).setup { nil }
    @config_file = File.dirname(__FILE__) + "/../../config/config.sample.yml"
  end

  it "provides a default configuration" do
    Integrity.new
    assert_equal Integrity.default_configuration, Integrity.config
  end

  it "loads configuration from a file" do
    logger = Logger.new("/dev/null")
    stub(Logger).new { logger }
    Integrity.new(@config_file)

    assert_equal "http://integrity.domain.tld", Integrity.config[:base_uri]
    assert_equal "/path/to/scm/exports",        Integrity.config[:export_directory]
  end

  it "takes configuration as an hash" do
    Integrity.new(:base_uri => "http://foo.org")
    assert_equal "http://foo.org", Integrity.config[:base_uri]
  end

  it "sets Bob's logger to the Integrity's one" do
    Integrity.new
    assert_same Bob.logger, Integrity.send(:logger)
  end

  it "sets Bob's export directory to Integrity's :export_directory option" do
    Integrity.new
    assert_same Bob.directory, Integrity.config[:export_directory]
  end
end
