require "dm-sweatshop"

include DataMapper::Sweatshop::Unique

class Array
  def pick
    self[rand(self.length)]
  end
end

Integrity::Project.fixture do
  { :name       => (name = unique { /\w+/.gen }),
    :scm        => "git",
    :uri        => "git://github.com/#{/\w+/.gen}/#{name}.git",
    :branch     => ["master", "test-refactoring", "lh-34"].pick,
    :command    => ["rake", "make", "ant -buildfile test.xml"].pick,
    :public     => [true, false].pick }
end

Integrity::Commit.fixture(:with_project) do
  project = Integrity::Project.first || Integrity::Project.gen
  Integrity::Commit.generate_attributes.update(:project_id => project.id)
end

Integrity::Project.fixture(:integrity) do
  { :name       => "Integrity",
    :scm        => "git",
    :uri        => "git://github.com/foca/integrity.git",
    :branch     => "master",
    :command    => "rake",
    :public     => true }
end

Integrity::Project.fixture(:my_test_project) do
  { :name       => "My Test Project",
    :scm        => "git",
    :uri        => File.dirname(__FILE__) + "/../../",
    :branch     => "master",
    :command    => "./test",
    :public     => true }
end

Integrity::Commit.fixture do
  { :identifier =>   Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
    :message =>      /[:sentence:]/.gen,
    :author =>       /\w+ \w+ <\w+@example.org>/.gen,
    :committed_at => unique {|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60)} }
end

Integrity::Commit.fixture(:successful) do
  Integrity::Commit.generate_attributes.update(:build => Integrity::Build.gen(:successful))
end

Integrity::Commit.fixture(:failed) do
  Integrity::Commit.generate_attributes.update(:build => Integrity::Build.gen(:failed))
end

Integrity::Commit.fixture(:pending) do
  Integrity::Commit.generate_attributes.update(:build => Integrity::Build.gen(:pending))
end

Integrity::Commit.fixture(:building) do
  Integrity::Commit.generate_attributes.update(:build => Integrity::Build.gen(:building))
end

Integrity::Build.fixture do
  commit = Integrity::Commit.first || Integrity::Commit.gen(:with_project)

  { :output       => /[:paragraph:]/.gen,
    :successful   => true,
    :started_at   => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
    :created_at   => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
    :completed_at => unique {|i| Time.mktime(2008, 12, 15, 18, i % 60) },
    :commit_id    => commit.id }
end

Integrity::Build.fixture(:successful) do
  Integrity::Build.generate_attributes.update(:successful => true)
end

Integrity::Build.fixture(:failed) do
  Integrity::Build.generate_attributes.update(:successful => false)
end

Integrity::Build.fixture(:pending) do
  Integrity::Build.generate_attributes.update(:successful => nil, :started_at => nil, :completed_at => nil)
end

Integrity::Build.fixture(:building) do
  Integrity::Build.generate_attributes.update(:completed_at => nil,
    :successful => nil, :output => nil)
end

Integrity::Notifier.fixture(:irc) do
  { :project => Integrity::Project.generate,
    :name => "IRC",
    :config => { :uri => "irc://irc.freenode.net/integrity" }}
end

Integrity::Notifier.fixture(:twitter) do
  { :project => Integrity::Project.generate,
    :name => "Twitter",
    :config => { :email => "foo@example.org", :pass => "secret" }}
end
