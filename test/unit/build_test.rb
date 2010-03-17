require "helper"

class BuildTest < IntegrityTest
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

  test "being destroyed" do
    build = Build.gen
    assert_change(Commit, :count, -1) { build.destroy }
  end
end
