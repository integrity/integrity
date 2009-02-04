require File.dirname(__FILE__) + "/../helpers"

class IntegrityTest < Test::Unit::TestCase
  it "loads configuration from a file" do
    file = File.dirname(__FILE__) + "/../../config/config.sample.yml"
    Integrity.load_config(file)

    Integrity.config[:base_uri].should == "http://integrity.domain.tld"
    Integrity.config[:export_directory].should == "/path/to/scm/exports"
  end

  it "is possible to access config as an hash" do
    Integrity.config[:foo] = "bar"
    Integrity.config[:foo].should == "bar"
  end
end
