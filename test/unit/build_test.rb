require File.dirname(__FILE__) + '/../helpers'

class BuildTest < Test::Unit::TestCase
  test "fixture is valid and can be saved" do
    lambda do
      build = Build.gen
      build.save

      build.should be_valid
    end.should change(Build, :count).by(1)
  end

  describe "Properties" do
    it "captures the build's STDOUT/STDERR" do
      assert ! Build.gen.output.empty?
    end

    it "knows if it failed or not" do
      assert Build.gen(:successful => true).successful?
      assert ! Build.gen(:successful => false).successful?
    end

    it "knows it's status" do
      assert_equal :success, Build.gen(:successful => true).status
      assert_equal :failed, Build.gen(:successful => false).status

      assert_equal :pending, Build.gen(:started_at => nil).status
    end
  end

  it "finds pending builds" do
    3.of { Build.gen(:started_at => nil) }
    2.of { Build.gen(:started_at => Time.mktime(2009, 1, 17, 23, 18)) }

    Build.should have(3).pending
  end
end
