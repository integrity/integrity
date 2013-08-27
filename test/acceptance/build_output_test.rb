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

  # This test checks that the intermediate build output is:
  # 1) non-empty, and
  # 2) different from final build output.
  scenario "Checking that intermediate build output is shown" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:long_building, :uri => repo.uri)

    login_as "admin", "test"
    visit "/long-building"
    click_button "manual build"
    
    # starts the build.
    # the build sleeps for 1 second after the repository is cloned, etc.
    start_build
    
    count = 0
    # wait at most 1 second, should be enough given build's sleep time
    while count < 10
      sleep 0.1
      visit "/long-building"
      if !response.body.include?('HEAD is building')
        break
      end
      count += 1
    end
    
    # here commit message may have been retrieved but no output
    # was collected yet, check and wait agian
    count = 0
    while count < 10
      field = field_by_xpath('//pre[@class="output"]')
      if field
        break
      end
      sleep 0.5
      visit current_url
      count += 1
    end

    # if there was a problem with the build machinery itself,
    # we may have never gotten to the building phase,
    # and body here would include "HEAD is building"
    assert_have_tag("h1", :content => "#{repo.short_head} is building")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    # partial output
    assert_have_tag("pre.output",   :content => "before sleep")
    
    # wait for the build to finish
    finish_build
    visit "/long-building"
    
    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    # complete output
    # on ruby 1.8.7 xpath does not understand newlines apparently
    #assert_have_tag("pre.output",   :content => "before sleep\nafter sleep")
    field = field_by_xpath('//pre[@class="output"]')
    assert field
    text = field.element.text.strip
    assert_equal "before sleep\nafter sleep", text
  end
end
