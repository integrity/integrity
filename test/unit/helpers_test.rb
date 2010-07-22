require "helper"

class HelpersTest < IntegrityTest
  setup { @h = Module.new { extend Integrity::Helpers } }

  test "pretty_date" do
    assert_equal "commit date not loaded", @h.pretty_date(nil)
    assert_equal "today",       @h.pretty_date(Time.now)
    assert_equal "yesterday",   @h.pretty_date(Time.new - 86400)

    assert_equal "on Dec 1st",  @h.pretty_date(Time.mktime(1995, 12, 01))
    assert_equal "on Dec 21st", @h.pretty_date(Time.mktime(1995, 12, 21))
    assert_equal "on Dec 31st", @h.pretty_date(Time.mktime(1995, 12, 31))

    assert_equal "on Dec 22nd", @h.pretty_date(Time.mktime(1995, 12, 22))
    assert_equal "on Dec 3rd",  @h.pretty_date(Time.mktime(1995, 12, 03))
    assert_equal "on Dec 23rd", @h.pretty_date(Time.mktime(1995, 12, 23))
    assert_equal "on Dec 15th", @h.pretty_date(Time.mktime(1995, 12, 15))
  end

  test "github urls" do
    project = Project.gen(:integrity)

    assert_equal "http://github.com/foca/integrity",
      @h.github_project_url(project).to_s

    build = Build.gen
    commit_id = build.sha1

    project.builds << build
    project.save

    assert_equal "http://github.com/foca/integrity/commit/#{commit_id}",
      @h.github_commit_url(build)

    project.update(:uri => "git@github.com:sr/integrity.git")

    assert_equal "http://github.com/sr/integrity",
      @h.github_project_url(project)

    project.update(:branch => "baz")
    assert_equal "http://github.com/sr/integrity/compare/master...baz",
      @h.github_project_url(project).to_s

    assert_equal "http://github.com/sr/integrity/commit/#{commit_id}",
      @h.github_commit_url(build)
  end
end
