require "helper/acceptance"

class LongCommitMessageLinesTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want Integrity to handle commit messages with very long lines,
    Truncating lines that are too long
  EOS

  setup do
    @repo = git_repo(:my_test_project)
    @repo.add_commit_with_very_long_commit_message_lines
    Project.gen(:my_test_project, :uri => @repo.uri)
    
    @builder = Integrity.config.builder
    Integrity.configure { |c|
      c.builder = :explicit, 1
    }
  end

  teardown do
    # TODO this dude shouldn't be leaking
    Integrity.config.instance_variable_set(:@builder, @builder)
  end

  def build
    Integrity.config.builder.wait!
  end

  scenario "Triggering a build" do
    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

=begin build is run asynchronously and may be not started, pending or finished
    within "#build" do
      assert_have_tag("h1",         :content => "HEAD hasn't been built yet")
      assert_have_tag("blockquote", :content => "message not loaded")
      assert_have_tag(".who",       :content => "author not loaded")
      assert_have_tag(".when",      :content => "commit date not loaded")
    end
=end

    build
    reload

    assert_have_tag("h1", :content => "Built #{@repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "end-subject")
    assert_have_tag("blockquote p", :content => "end-body")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "Running tests...")
  end
end
