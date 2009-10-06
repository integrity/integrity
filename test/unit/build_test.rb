require "helper"

class BuildTest < Test::Unit::TestCase
  test "fixture is valid and can be saved" do
    assert_change(Build, :count) {
      build = Build.gen
      assert build.valid? && build.save
    }
  end

  it "has an output" do
    assert ! Build.gen.output.empty?
    assert_equal "", Build.new.output
  end

  it "knows its status" do
    assert Build.gen(:successful => true).successful?
    assert ! Build.gen(:successful => false).successful?
  end

  it "knows it's status" do
    assert_equal :success, Build.gen(:successful => true).status
    assert_equal :failed, Build.gen(:successful => false).status

    assert_equal :pending, Build.gen(:started_at => nil).status
  end

  it "finds pending builds" do
    3.of { Build.gen(:started_at => nil) }
    2.of { Build.gen(:started_at => Time.mktime(2009, 1, 17, 23, 18)) }

    assert_equal 3, Build.pending.count
  end
end
