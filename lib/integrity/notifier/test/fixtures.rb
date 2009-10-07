require "dm-sweatshop"

class Array
  def pick
    self[rand(self.length)]
  end unless method_defined?(:pick)
end

module Integrity
  extend DataMapper::Sweatshop::Unique

  Project.fixture do
    { :name    => (name = unique { /\w+/.gen }),
      :scm     => "git",
      :uri     => "git://github.com/#{/\w+/.gen}/#{name}.git",
      :branch  => %w[master test-refactoring lh-34].pick,
      :command => %w[rake make ant test.xml].pick,
      :public  => true }
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

  Project.fixture(:misc_builds) do
    Project.gen_attrs.update(:builds => \
      2.of { Build.gen(:failed) }     +
      2.of { Build.gen(:pending) }    +
      1.of { Build.gen(:building) }   +
      3.of { Build.gen(:successful) })
  end

  Project.fixture(:svn) do
    Project.gen_attrs(:my_test_project).update(:scm => "svn", :branch => "")
  end

  Project.fixture(:blank) do
    Project.gen_attrs.update(:builds => [])
  end

  Project.fixture(:successful) do
    Project.gen_attrs.update(:builds => 2.of{Build.gen(:failed)} +
      1.of{Build.gen(:successful)})
  end

  Project.fixture(:failed) do
    Project.gen_attrs.update(:builds => 2.of{Build.gen(:successful)} +
      1.of{Build.gen(:failed)})
  end

  Project.fixture(:pending) do
    Project.gen_attrs.update(:builds => 2.of{Build.gen} +
      1.of{Build.gen(:pending)})
  end

  Project.fixture(:building) do
    Project.gen_attrs.update(:builds => 3.of{Build.gen} +
      1.of{Build.gen(:building)})
  end

  Project.fixture(:blank) do
    Project.gen_attrs.update(:builds => [])
  end

  Build.fixture do
    { :output       => /[:paragraph:]/.gen,
      :successful   => [true, false].pick,
      :started_at   => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
      :created_at   => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
      :completed_at => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
      :commit       => Commit.gen }
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
      unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) })
  end

  Commit.fixture do
    { :identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
      :message    => /[:sentence:]/.gen,
      :author     => /\w+ \w+ <\w+@example.org>/.gen,
      :committed_at =>
        unique{|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60)} }
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
