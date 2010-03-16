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

  it "public" do
    assert Project.gen(:public => "1").public?
    assert ! Project.gen(:public => "0").public?
    assert Project.gen(:public => "false").public?
    assert Project.gen(:public => "true").public?
    assert ! Project.gen(:public => false).public?
    assert ! Project.gen(:public => nil).public?
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

  # XXX
  describe "When updating its notifiers" do
    setup do
      twitter = Notifier.gen(:twitter, :enabled => true)
      irc     = Notifier.gen(:irc,     :enabled => false)

      @project = Project.gen(:notifiers => [twitter, irc])
    end

    it "creates and enable the given notifiers" do
      Notifier.all.destroy!

      project = Project.gen
      project.update_notifiers(["IRC", "Twitter"],
          {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})

      assert_equal 2,         Notifier.count
      assert_equal 2,         project.enabled_notifiers.count

      notifier_names = project.notifiers.map { |n| n.name }
      assert notifier_names.include?("IRC")
      assert notifier_names.include?("Twitter")

      project.update_notifiers(["Twitter"],
          {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})

      assert_equal 2, Notifier.count
      assert ! project.notifies?("IRC")
      assert   project.notifies?("Twitter")
    end

    it "creates notifiers present in config even when they're disabled" do
      @project.update_notifiers(["IRC"],
        {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
         "Twitter" => {"username" => "john"}})

      assert_equal 2, @project.notifiers.count
    end

    it "disables notifiers that are not included in the list" do
      @project.update_notifiers(["IRC"],
          {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})

      @project.update_notifiers(["IRC"],
        {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"}})

      assert ! @project.notifiers.first(:name => "Twitter").enabled?
      assert   @project.notifiers.first(:name => "IRC").enabled?
    end

    it "preserves config of notifiers that are being disabled" do
      @project.update_notifiers(["IRC"],
        {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
          "Twitter" => {"username" => "john"}})

      assert_equal "john",
        @project.notifiers.first(:name => "Twitter").config["username"]
    end

    it "does nothing if given nil as the list of notifiers to enable" do
      assert_no_change(Notifier, :count) {
        Project.gen.update_notifiers(nil, {})
      }
    end

    it "doesn't destroy any of the other notifiers that exist for other projects" do
      irc     = Notifier.gen(:irc)
      project = Project.gen
      project.update_notifiers("IRC", {"IRC" => irc.config})

      assert_no_change(project.notifiers, :count) {
        Project.gen.update_notifiers("IRC", {"IRC" => irc.config})
      }
    end
  end

  describe "When retrieving state about its notifier" do
    setup do
      @project = Project.gen
      @irc     = Notifier.gen(:irc)
    end

    it "knows which notifiers are enabled" do
      notifiers = [Notifier.gen(:irc, :enabled => false),
        Notifier.gen(:twitter, :enabled => true)]
      project = Project.gen(:notifiers => notifiers)

      assert_equal 1, project.enabled_notifiers.size
    end

    test "#config_for returns given notifier's configuration" do
      @project.update(:notifiers => [@irc])
      assert_equal({:uri => "irc://irc.freenode.net/integrity"},
        @project.config_for("IRC"))
    end

    test "#config_for returns an empty hash for unknown notifier" do
      assert_equal({}, @project.config_for("IRC"))
    end

    test "#notifies? is true if the notifier exists and is enabled" do
      assert ! @project.notifies?("UndefinedNotifier")

      @project.update(:notifiers =>
        [ Notifier.gen(:irc, :enabled     => true),
          Notifier.gen(:twitter, :enabled => false) ])

      assert @project.notifies?("IRC")
      assert ! @project.notifies?("Twitter")
    end
  end
end
