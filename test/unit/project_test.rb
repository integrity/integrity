require "helper"

class ProjectTest < Test::Unit::TestCase
  test "fixture is valid and can be saved" do
    assert_change(Project, :count) {
      project = Project.gen
      assert project.valid? && project.save
    }
  end

  describe "Properties" do
    before(:each) do
      @project = Project.gen(:integrity)
    end

    it "has a name" do
      assert_equal "Integrity", @project.name
    end

    it "has a permalink" do
      assert_equal "integrity", @project.permalink

      assert_equal "foos-bar-baz-and-bacon",
        Project.gen(:name => "foo's bar/baz and BACON?!").permalink
    end

    it "has an URI" do
      assert_equal "git://github.com/foca/integrity.git",
        @project.uri.to_s
    end

    it "has an SCM" do
      assert_equal "git", @project.scm
      assert_equal "git", Project.new.scm
    end

    it "has a branch" do
      assert_equal "master", @project.branch
      assert_equal "",       Project.new.branch
    end

    it "has a command" do
      assert_equal "rake", @project.command
      assert_equal "rake", Project.new.command
    end

    it "knows it's visibility" do
      assert Project.new.public?

      assert @project.public?
      assert Project.gen(:public => "1").public?
      assert ! Project.gen(:public => "0").public?

      assert Project.gen(:public => "false").public?
      assert Project.gen(:public => "true").public?
      assert ! Project.gen(:public => false).public?
      assert ! Project.gen(:public => nil).public?
    end

    it "has created_at and updated_at timestamps" do
      assert_kind_of DateTime, @project.created_at
      assert_kind_of DateTime, @project.updated_at
    end

    it "knows it's status" do
      assert_equal :success,
        Project.gen(:commits => 1.of{ Commit.gen(:successful) }).status

      assert_equal :success,
        Project.gen(:commits => 2.of{ Commit.gen(:successful) }).status

      assert_equal :failed,
        Project.gen(:commits => 2.of{ Commit.gen(:failed) }).status

      assert_equal :pending,
        Project.gen(:commits => 1.of{ Commit.gen(:pending) }).status

      assert_equal :blank, Project.gen(:commits => []).status

      assert_equal :building,
        Project.gen(:commits => 1.of{ Commit.gen(:building) }).status

      commits = 3.of{Commit.gen(:successful)} << Commit.gen(:building)
      assert Project.gen(:commits => commits).building?
    end
  end

  describe "Validation" do
    it "requires a name" do
      assert_no_change(Project, :count) {
        assert ! Project.gen(:name => nil).valid?
      }
    end

    it "ensures its name is unique" do
      Project.gen(:name => "Integrity")

      assert_no_change(Project, :count) {
        assert ! Project.gen(:name => "Integrity").valid?
      }
    end

    it "requires an URI" do
      assert_no_change(Project, :count) {
        assert ! Project.gen(:uri => nil).valid?
      }
    end

    it "requires an SCM" do
      assert_no_change(Project, :count) {
        ! Project.gen(:scm => nil).valid?
      }
    end

    it "requires a command" do
      assert_no_change(Project, :count) {
        assert ! Project.gen(:command => nil).valid?
      }
    end
  end

  it "orders projects by name" do
    rails   = Project.gen(:name => "rails",   :public => true)
    merb    = Project.gen(:name => "merb",    :public => true)
    sinatra = Project.gen(:name => "sinatra", :public => true)
    camping = Project.gen(:name => "camping", :public => false)

    assert_equal [camping, merb, rails, sinatra], Project.all
    assert_equal [merb, rails, sinatra], Project.all(:public => true)
  end

  test "destroying itself" do
    project = Project.generate(:commits => 7.of{ Commit.gen })

    assert_change(Commit, :count, -7) {  project.destroy }
    assert ! Project[project.id]
  end

  test "finding its previous builds" do
    project = Project.gen(:commits => 5.of{ Commit.gen })

    assert_equal 4,  project.previous_commits.count
    assert_equal [], Project.gen(:commits => [Commit.gen]).previous_commits
    assert_equal [], Project.gen(:commits => []).previous_commits

    assert project.previous_commits.first.committed_at >
      project.previous_commits.last.committed_at

    assert ! Project.gen(:commits => []).last_commit
    assert ! project.previous_commits.include?(project.last_commit)
  end

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
      irc     = Notifier.generate(:irc)
      project = Project.gen
      project.update_notifiers("IRC", {"IRC" => irc.config})

      assert_no_change(project.notifiers, :count) {
        Project.gen.update_notifiers("IRC", {"IRC" => irc.config})
      }
    end
  end

  describe "When retrieving state about its notifier" do
    before(:each) do
      @project = Project.gen
      @irc     = Notifier.generate(:irc)
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
