require "helper/acceptance"

class ManualBuildTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to see build output while my project is building
    So that I have immediate feedback
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

  def start_build
    @thread = Thread.new do
      Integrity.config.builder.wait!
    end
    @thread.run
  end
  
  def finish_build
    @thread.join
  end

  scenario "Buliding" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:long_building, :uri => repo.uri)

    login_as "admin", "test"
    visit "/long-building"
    click_button "manual build"
    
    start_build
    sleep 0.5
    visit "/long-building"

    assert_have_tag("h1", :content => "#{repo.short_head} is building")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "before sleep")
    
    finish_build
    visit "/long-building"
    
    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    # on ruby 1.8.7 xpath does not understand newlines apparently
    #assert_have_tag("pre.output",   :content => "before sleep\nafter sleep")
    field = field_by_xpath('//pre[@class="output"]')
    assert field
    text = field.element.text.strip
    assert_equal "before sleep\nafter sleep", text
  end
end
