require "helper"

class ProjectTest < IntegrityTest
  test "all" do
    rails   = Project.gen(:name => "rails")
    camping = Project.gen(:name => "camping")
    sinatra = Project.gen(:name => "sinatra")

    assert_equal [camping, rails, sinatra], Project.all
  end

  test "destroy" do
    project = Project.gen(:builds => 2.of{Build.gen})
    assert_change(Build, :count, -2) { project.destroy }
  end

  test "sorted_builds" do
    project = Project.gen(:builds => 5.of{Build.gen})
    first   = project.sorted_builds.first
    last    = project.sorted_builds.last

    assert first.created_at > last.created_at
  end

  test "status" do
    assert_equal :blank,    Project.gen(:blank).status
    assert_equal :success,  Project.gen(:successful).status
    assert_equal :failed,   Project.gen(:failed).status
    assert_equal :pending,  Project.gen(:pending).status
    assert_equal :building, Project.gen(:building).status
  end

  test "permalink" do
    assert_equal "integrity", Project.gen(:integrity).permalink
    assert_equal "foos-bar-baz-and-bacon",
      Project.gen(:name => "foo's bar/baz and BACON?!").permalink
  end

  test "defaults" do
    assert_equal "master", Project.new.branch
    assert_equal "rake", Project.new.command
    assert Project.new.public?
  end

  test "validations" do
    assert_no_change(Project, :count) {
      assert ! Project.gen(:name => nil).valid?
    }

    assert_no_change(Project, :count) {
      assert ! Project.gen(:uri => nil).valid?
    }

    assert_no_change(Project, :count) {
      assert ! Project.gen(:branch => nil).valid?
    }

    assert_no_change(Project, :count) {
      assert ! Project.gen(:command => nil).valid?
    }

    Project.gen(:name => "Integrity")

    assert_no_change(Project, :count) {
      assert ! Project.gen(:name => "Integrity").valid?
    }
  end

  test "fork" do
    project = Project.gen(:integrity, :notifiers => [Notifier.gen(:irc)])

    forked = assert_change(Project, :count, 1) { project.fork("fork") }

    assert_equal "Integrity (fork)", forked.name
    assert_equal "fork",             forked.branch
    assert_equal project.uri,        forked.uri
    assert_equal project.command,    forked.command
    assert_equal project.public,     forked.public

    assert_equal 2, Notifier.count
    assert project.notifiers.first.config[:uri].include?("irc://")
  end

  test "github" do
    assert Project.gen(:integrity).github?
    assert ! Project.gen(:my_test_project).github?
  end

end
