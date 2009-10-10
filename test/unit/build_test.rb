require "helper"

class BuildTest < Test::Unit::TestCase
  test "fixture is valid and can be saved" do
    # TODO: useless test?
    assert_change(Build, :count) {
      build = Build.gen(:project => Project.gen)
      assert build.valid? && build.save
    }
  end

  it "has an output" do
    assert ! Build.gen.output.empty?
    assert_equal "", Build.new.output
  end

  it "knows it's status" do
    assert Build.gen(:successful).successful?
    assert ! Build.gen(:failed).successful?

    assert_equal :success,  Build.gen(:successful).status
    assert_equal :failed,   Build.gen(:failed).status
    assert_equal :pending,  Build.gen(:pending).status
    assert_equal :building, Build.gen(:building).status
  end

  it "has a human readable status" do
    assert_match /^Built (.*?) successfully$/,
      Build.gen(:successful).human_status

    assert_match /^Built (.*?) and failed$/,
      Build.gen(:failed).human_status

    assert_match /^(.*?) is building$/,
      Build.gen(:building).human_status

    assert_equal "This commit hasn't been built yet",
      Build.gen(:pending).human_status
  end

  it "finds pending builds" do
    3.of{Build.gen(:pending)}
    2.of{Build.gen(:building)}

    assert_equal 3, Build.pending.count
  end
end
