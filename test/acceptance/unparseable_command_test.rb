require "helper/acceptance"

class UnparseableCommandTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to see the error when trying to build a project with an unparseable command
    So that I can fix the command easily
  EOS

  setup do
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

  scenario "Unparseable command" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:unparseable_command, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "Syntax error")
  end
end
