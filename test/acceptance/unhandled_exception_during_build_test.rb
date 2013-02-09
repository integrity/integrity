require "helper/acceptance"

class UnhandledExceptionDuringBuildTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    When there is an unhandled exception during build
    I want the build to fail
    So that I know that the project is finished building
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
  
  class AnUnhandledException < StandardError
  end

  scenario "Unhandled exception in build" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    stub.instance_of(Integrity::Builder).run do
      raise AnUnhandledException
    end
    
    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "UnhandledExceptionDuringBuildTest::AnUnhandledException")
  end
end
