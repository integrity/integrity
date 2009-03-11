require File.dirname(__FILE__) + "/../helpers"

class IntegrityTest < Test::Unit::TestCase
  test "Integrity.new loads configuration from a file" do
    stub(DataMapper).setup { nil }

    file = File.dirname(__FILE__) + "/../../config/config.sample.yml"
    Integrity.new(file)

    Integrity.config[:base_uri].should == "http://integrity.domain.tld"
    Integrity.config[:export_directory].should == "/path/to/scm/exports"
  end

  specify "config is just a hash" do
    Integrity.config[:foo] = "bar"
    Integrity.config[:foo].should == "bar"
  end
end
