require "helper"

class BaseNotifierTest < IntegrityTest
  setup do
    @build    = Build.gen(:successful, :project => Project.gen)
    @notifier = Notifier::Base.new(@build, {})
    Integrity.configure { |c| c.base_url "http://ci.example.org" }
  end

  it "requires to implement .to_haml" do
    assert_raise(NotImplementedError) { Notifier::Base.to_haml }
  end

  it "requires to implement #deliver!" do
    assert_raise(NotImplementedError) { @notifier.deliver! }
  end

  it "provides a build url" do
    assert @notifier.build_url.to_s.include?("http")
  end

  it "provides a short message" do
    assert_equal "Built #{@build.commit.short_identifier} successfully",
      @notifier.short_message
  end

  it "provides a full message" do
    assert @notifier.full_message.include?(@build.human_status)
    assert @notifier.full_message.include?(@build.commit.message)
    assert @notifier.full_message.include?(@build.commit.committed_at.to_s)
    assert @notifier.full_message.include?(@build.commit.author.name)
    assert @notifier.full_message.include?(@notifier.build_url)
    assert @notifier.full_message.include?(@build.output)
  end
end
