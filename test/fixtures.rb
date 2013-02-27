require "dm-sweatshop"

class Array
  def pick
    self[rand(self.length)]
  end unless method_defined?(:pick)
end

module Integrity
  extend DataMapper::Sweatshop::Unique

  Project.fixture do
    { :name    => (name = unique(:project_name) { /\w+/.gen }),
      :uri     => "git://github.com/#{/\w+/.gen}/#{name}.git",
      :branch  => Randgen.word,
      :command => Randgen.word,
      :public  => true }
  end

  Project.fixture(:integrity) do
    { :name    => "Integrity",
      :uri     => "git://github.com/foca/integrity.git",
      :branch  => "master",
      :command => "rake",
      :public  => true }
  end

  Project.fixture(:my_test_project) do
    { :name    => "My Test Project",
      :uri     => File.dirname(__FILE__) + "/../../",
      :branch  => "master",
      :command => "./test",
      :public  => true }
  end

  Project.fixture(:echo_integrity_branch) do
    { :name    => "My Test Project",
      :uri     => File.dirname(__FILE__) + "/../../",
      :branch  => "master",
      :command => "echo branch=$INTEGRITY_BRANCH",
      :public  => true }
  end

  Project.fixture(:echo_integrity_branch_chained) do
    { :name    => "My Test Project",
      :uri     => File.dirname(__FILE__) + "/../../",
      :branch  => "master",
      :command => "true && echo branch=$INTEGRITY_BRANCH",
      :public  => true }
  end
  
  Project.fixture(:unparseable_command) do
    { :name    => "My Test Project",
      :uri     => File.dirname(__FILE__) + "/../../",
      :branch  => "master",
      :command => "if true; then",
      :public  => true }
  end

  Project.fixture(:misc_builds) do
    builds = 
      2.of { Build.gen(:failed) }     +
      2.of { Build.gen(:pending) }    +
      1.of { Build.gen(:building) }   +
      3.of { Build.gen(:successful) }
    Project.gen_attrs.update(:builds => builds, :last_build => builds.last)
  end

  Project.fixture(:blank) do
    Project.gen_attrs.update(:builds => [])
  end

  Project.fixture(:successful) do
    builds = 2.of{Build.gen(:failed)} +
      1.of{Build.gen(:successful)}
    Project.gen_attrs.update(:builds => builds, :last_build => builds.last)
  end

  Project.fixture(:failed) do
    builds = 2.of{Build.gen(:successful)} +
      1.of{Build.gen(:failed)}
    Project.gen_attrs.update(:builds => builds, :last_build => builds.last)
  end

  Project.fixture(:pending) do
    builds = 1.of{Build.gen} +
      1.of{Build.gen(:pending)}
    Project.gen_attrs.update(:builds => builds, :last_build => builds.last)
  end

  Project.fixture(:building) do
    builds = 3.of{Build.gen} +
      1.of{Build.gen(:building)}
    Project.gen_attrs.update(:builds => builds, :last_build => builds.last)
  end
  
  Project.fixture(:bogus_repo_project) do
    { :name    => "My Test Project",
      :uri     => 'nonexistent',
      :branch  => "master",
      :command => "./test",
      :public  => true }
  end

  Project.fixture(:long_building) do
    { :name    => "Long building",
      :uri     => "git://github.com/foca/integrity.git",
      :branch  => "master",
      :command => "echo before sleep; sleep 1; echo after sleep",
      :public  => true }
  end

  Build.fixture do
    { :output       => /[:paragraph:]/.gen,
      :successful   => [true, false].pick,
      :started_at   => unique(:build_started_at) {|i| Time.mktime(2008, 12, 15, i / 60, i % 40) },
      :created_at   => unique(:build_created_at) {|i| Time.mktime(2008, 12, 15, i / 60, i % 40) },
      :completed_at => unique(:build_completed_at) {|i| Time.mktime(2008, 12, 15, i / 60, i % 40 + 2) },
      :commit       => Commit.gen,
      :project      => Project.gen }
  end

  Build.fixture(:successful) do
    Build.gen_attrs.update(:successful => true)
  end

  Build.fixture(:failed) do
    Build.gen_attrs.update(:successful => false)
  end

  Build.fixture(:pending) do
    Build.gen_attrs.update(:started_at => nil)
  end

  Build.fixture(:building) do
    Build.gen_attrs.update(:completed_at => nil, :started_at =>
      unique(:build_building) {|i| Time.mktime(2008, 12, 15, 18, i % 60) })
  end

  Commit.fixture do
    { :identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
      :message    => /[:sentence:]/.gen,
      :author     => /\w+ \w+ <\w+@example.org>/.gen,
      :committed_at =>
        unique(:commit_committed_at) {|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60)} }
  end

  Commit.fixture(:successful) do
    { :identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
      :message    => /[:sentence:]/.gen,
      :author     => /\w+ \w+ <\w+@example.org>/.gen,
      :committed_at =>
        unique(:commit_committed_at_successful) {|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60)},
      :build => Build.gen_attrs.update(:successful => true) }
  end

  Commit.fixture(:failed) do
    { :identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
      :message    => /[:sentence:]/.gen,
      :author     => /\w+ \w+ <\w+@example.org>/.gen,
      :committed_at =>
        unique(:commit_committed_at_failed) {|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60)},
      :build => Build.gen_attrs.update(:successful => false) }
  end

  Notifier.fixture(:irc) do
    { :project => Project.gen,
      :name => "IRC",
      :config => { :uri => "irc://irc.freenode.net/integrity" }}
  end

  Notifier.fixture(:twitter) do
    { :project => Project.gen,
      :name => "Twitter",
      :config => { :email => "foo@example.org", :pass => "secret" }}
  end
end
