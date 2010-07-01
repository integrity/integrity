require "helper"

class BuildTest < IntegrityTest
  test "output" do
    assert ! Build.gen.output.empty?
    assert_equal "", Build.new.output
  end

  test "status" do
    assert Build.gen(:successful).successful?
    assert ! Build.gen(:failed).successful?

    assert_equal :success,  Build.gen(:successful).status
    assert_equal :failed,   Build.gen(:failed).status
    assert_equal :pending,  Build.gen(:pending).status
    assert_equal :building, Build.gen(:building).status
  end

  test "human status" do
    assert_match /^Built (.*?) successfully$/,
      Build.gen(:successful).human_status

    assert_match /^Built (.*?) and failed$/,
      Build.gen(:failed).human_status

    assert_match /^(.*?) is building$/,
      Build.gen(:building).human_status

    build = Build.gen(:pending)
    assert_equal "#{build.commit.short_identifier} hasn't been built yet",
      build.human_status
  end

  test "commit data" do
    build = Build.gen(:commit => Commit.gen(
      :identifier   => "6f2ec35bc09744f55e528fe98a438dcb704edc65",
      :message      => "init",
      :author       => "Simon Rozet <simon@rozet.name>",
      :committed_at => Time.utc(2008, 10, 12, 14, 18, 20)
    ))

    assert_equal "init",        build.message
    assert_equal "Simon Rozet", build.author
    assert_kind_of DateTime,    build.committed_at
    assert build.identifier.include?(build.short_identifier)
  end

  test "destroy" do
    build = Build.gen
    assert_change(Commit, :count, -1) { build.destroy }
  end
end
