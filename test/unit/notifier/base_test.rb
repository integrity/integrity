require File.dirname(__FILE__) + "/../../helpers"

class BaseNotifierTest < Test::Unit::TestCase
  before(:each) do
    @commit = Commit.gen(:successful)
    @base = Notifier::Base.new(@commit, {})
  end

  it "requires to implement .to_haml" do
    assert_raise(NotImplementedError) { Notifier::Base.to_haml }
  end

  it "requires to implement #deliver!" do
    assert_raise(NotImplementedError) { @base.deliver! }
  end

  it "provides a short message" do
    assert_equal "Built #{@commit.short_identifier} successfully", @base.short_message
  end

  it "provides a full message" do
    assert @base.full_message.include?("Commit Message: #{@commit.message}")
    assert @base.full_message.include?("Commit Date: #{@commit.committed_at}")
    assert @base.full_message.include?("Commit Author: #{@commit.author.name}")
    assert @base.full_message.include?("Link: #{@base.commit_url}")
    assert @base.full_message.include?("Build Output")
    assert @base.full_message.include?(@commit.build.output)
  end

  it "provides a commit url" do
    assert_equal "http://localhost:8910/#{@commit.project.name}" +
      "/commits/#{@commit.identifier}", @base.commit_url
  end

  test "deprecated methods" do
    silence_warnings {
      assert_equal @base.commit, @base.build
      assert_equal @base.commit_url, @base.build_url
      assert_equal @base.send(:stripped_commit_output),
        @base.send(:stripped_build_output)
    }
  end
end
