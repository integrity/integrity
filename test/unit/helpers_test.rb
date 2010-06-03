require "helper"

class HelpersTest < IntegrityTest
  setup { @h = Module.new { extend Integrity::Helpers } }

  test "pretty_date" do
    assert_equal "unknown",     @h.pretty_date(DateTime.new)
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

    commit    = Commit.gen
    commit_id = commit.identifier
    project.builds << Build.gen(:successful, :commit => commit)
    project.save

    assert_equal "http://github.com/foca/integrity/commit/#{commit_id}",
      @h.github_commit_url(commit)

    project.update(:uri => "git@github.com:sr/integrity.git")

    assert_equal "http://github.com/sr/integrity",
      @h.github_project_url(project)

    project.update(:branch => "baz")
    assert_equal "http://github.com/sr/integrity/compare/master...baz",
      @h.github_project_url(project).to_s

    assert_equal "http://github.com/sr/integrity/commit/#{commit_id}",
      @h.github_commit_url(commit)
  end
  
  test "bash_color_codes" do
    bash = "Test string \e[31m31\e[0m, \e[32m32\e[0m, \e[33m33\e[0m, \e[34m34\e[0m, \e[35m35\e[0m, \e[36m36\e[0m, \e[37m37\e[0m"
    html = "Test string <span class=\"color31\">31</span>, <span class=\"color32\">32</span>, <span class=\"color33\">33</span>, <span class=\"color34\">34</span>, <span class=\"color35\">35</span>, <span class=\"color36\">36</span>, <span class=\"color37\">37</span>"
    
    assert_equal @h.bash_color_codes(bash), html
  end
end
