require "helper/acceptance/textfile_notifier"

class NotifierTest < IntegrityTest
  test "fixture is valid and can be saved" do
    assert_change(Notifier, :count) {
      notifier = Notifier.gen(:irc)
      assert notifier.valid? && notifier.save
    }
  end

  test "properties" do
    notifier = Notifier.gen(:irc)

    assert_equal "IRC", notifier.name
    assert_equal({:uri => "irc://irc.freenode.net/integrity"}, notifier.config)
  end

  it "requires a name" do
    assert_no_change(Notifier, :count) { Notifier.gen(:irc, :name => nil) }
  end

  it "requires a config" do
    assert_no_change(Notifier, :count) { Notifier.gen(:irc, :config => nil) }
  end

  it "requires an unique name in project scope" do
    project = Project.gen
    irc     = Notifier.gen(:irc, :project => project)

    assert_no_change(project.notifiers, :count) {
      project.notifiers << Notifier.gen(:irc, :config => "foo")
      project.save
    }
  end
end
__END__
TODO
  it "handles notifier timeouts" do
    pending("Move to acceptance tests") {
      irc   = Notifier.gen(:irc)
      Notifier.register(Integrity::Notifier::IRC)
      build = Build.gen

      stub.instance_of(Notifier::IRC).deliver! { raise Timeout::Error }
      mock(Integrity).log(anything)
      mock(Integrity).log("Integrity::Notifier::IRC notifier timed out") { nil }

      irc.notify_of_build(build)
    }
  end
end
