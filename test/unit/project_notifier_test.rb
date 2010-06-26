class ProjectNotifier < IntegrityTest
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

class ProjectNotifierUpdate < IntegrityTest
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
