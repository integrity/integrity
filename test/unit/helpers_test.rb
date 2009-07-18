require File.dirname(__FILE__) + "/../helpers"

class HelpersTest < Test::Unit::TestCase
  setup do
    @h = Module.new { extend Integrity::Helpers }
  end

  test "#pretty_date" do
    @h.pretty_date(Time.now).should == "today"
    @h.pretty_date(Time.new - 86400).should == "yesterday"

    @h.pretty_date(Time.mktime(1995, 12, 01)).should == "on Dec 1st"
    @h.pretty_date(Time.mktime(1995, 12, 21)).should == "on Dec 21st"
    @h.pretty_date(Time.mktime(1995, 12, 31)).should == "on Dec 31st"

    @h.pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"
    @h.pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"

    @h.pretty_date(Time.mktime(1995, 12, 03)).should == "on Dec 3rd"
    @h.pretty_date(Time.mktime(1995, 12, 23)).should == "on Dec 23rd"

    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
  end

  describe "urls" do
    before do
      Integrity.config[:base_uri] = "http://example.org/ci"

      @project = Project.gen(:name => "Foo Bar")
      @build   = Build.gen(:successful)
      @commit  = @build.commit
    end

    test "root" do
      assert_equal "http://example.org/ci", @h.root_url.to_s
      assert_equal "/ci", @h.root_path
      assert_equal "/ci/stylesheet.css", @h.root_path("/stylesheet.css")

      Integrity.config[:base_uri] = nil
      @h.instance_variable_set(:@url, nil)
      lambda { @h.root_url }.should raise_error

      stub(@h).request { OpenStruct.new(:url => "http://0.0.0.0/") }
      assert_equal "http://0.0.0.0/", @h.root_url.to_s
    end

    test "project" do
      assert_equal "/ci/foo-bar", @h.project_path(@project)
      assert_equal "http://example.org/ci/foo-bar",
        @h.project_url(@project).to_s
    end

    test "commit" do
      assert_equal "/ci/foo-bar/commits/#{@commit.identifier}",
        @h.commit_path(@build.commit)
      assert_equal "http://example.org/ci/foo-bar/commits/#{@commit.identifier}",
        @h.commit_url(@build.commit).to_s
    end

    test "build commit" do
      assert_equal "/ci/foo-bar/commits/#{@commit.identifier}/builds",
        @h.commit_path(@build.commit, :builds)
      assert_equal "http://example.org/ci/foo-bar/commits/#{@commit.identifier}/builds",
        @h.commit_url(@build.commit, :builds).to_s
    end
  end
end
