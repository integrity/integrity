require "dm-sweatshop"

class Array
  def pick
    self[rand(self.length)]
  end
end

module Integrity
  extend DataMapper::Sweatshop::Unique

  Project.fixture do
    { :name    => (name = unique { /\w+/.gen }),
      :scm     => "git",
      :uri     => "git://github.com/#{/\w+/.gen}/#{name}.git",
      :branch  => %w[master test-refactoring lh-34].pick,
      :command => %w[rake make ant test.xml].pick,
      :public  => [true, false].pick }
  end

  Project.fixture(:integrity) do
    { :name    => "Integrity",
      :scm     => "git",
      :uri     => "git://github.com/foca/integrity.git",
      :branch  => "master",
      :command => "rake",
      :public  => true }
  end

  Project.fixture(:my_test_project) do
    { :name    => "My Test Project",
      :scm     => "git",
      :uri     => File.dirname(__FILE__) + "/../../",
      :branch  => "master",
      :command => "./test",
      :public  => true }
  end

  Commit.fixture do
    { :identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
      :message    => /[:sentence:]/.gen,
      :author     => /\w+ \w+ <\w+@example.org>/.gen,
      :committed_at => unique{|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60)}}
  end

  Commit.fixture(:with_project) do
    Commit.gen_attrs.update(:project => Project.first || Project.gen)
  end

  Commit.fixture(:successful) do
    Commit.gen_attrs.update(:build => Build.gen(:successful))
  end

  Commit.fixture(:failed) do
    Commit.gen_attrs.update(:build => Build.gen(:failed))
  end

  Commit.fixture(:pending) do
    Commit.gen_attrs.update(:build => Build.gen(:pending))
  end

  Commit.fixture(:building) do
    Commit.gen_attrs.update(:build => Build.gen(:building))
  end

  Build.fixture do
    commit = Commit.first || Commit.gen(:with_project)

    { :output       => /[:paragraph:]/.gen,
      :successful   => true,
      :started_at   => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
      :created_at   => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
      :completed_at => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
      :commit_id    => commit.id }
  end

  Build.fixture(:successful) do
    Build.gen_attrs.update(:successful => true)
  end

  Build.fixture(:failed) do
    Build.gen_attrs.update(:successful => false)
  end

  Build.fixture(:pending) do
    Build.gen_attrs.update(:successful => nil, :started_at => nil,
      :completed_at => nil)
  end

  Build.fixture(:building) do
    Build.gen_attrs.update(:completed_at => nil,
      :successful => nil, :output => nil)
  end

  Notifier.fixture(:irc) do
    { :project => Project.generate,
      :name => "IRC",
      :config => { :uri => "irc://irc.freenode.net/integrity" }}
  end

  Notifier.fixture(:twitter) do
    { :project => Project.generate,
      :name => "Twitter",
      :config => { :email => "foo@example.org", :pass => "secret" }}
  end
end
