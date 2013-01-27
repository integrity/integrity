# coding: utf-8

require "helper/acceptance"

class Utf8Test < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to be able to build projects that use UTF-8 in commits or build output
    So that I know if they build properly
  EOS

  setup do
    @builder = Integrity.config.builder
    Integrity.configure { |c|
      c.builder = :threaded, 1
    }
  end

  teardown do
    # TODO this dude shouldn't be leaking
    Integrity.config.instance_variable_set(:@builder, @builder)
  end

  def build
    Integrity.config.builder.wait!
  end

  scenario "Building a commit with UTF-8 in subject and message" do
    repo = git_repo(:my_test_project)
    repo.add_commit_with_utf8_subject_and_body
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "Коммит")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "Running tests...")
  end

  scenario "Building a commit with UTF-8 in command output" do
    repo = git_repo(:my_test_project)
    repo.add_commit_with_utf8_command_output
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "Тесты выполняются...")
  end
end
