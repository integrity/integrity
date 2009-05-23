require File.dirname(__FILE__) + "/../helpers"

class MigrationsTest < Test::Unit::TestCase
  def database_adapter
    DataMapper.repository(:default).adapter
  end

  def table_exists?(table_name)
    database_adapter.storage_exists?(table_name)
  end

  def current_migrations
    database_adapter.query("SELECT * from migration_info")
  end

  def load_initial_migration_fixture
    database_adapter.execute(File.read(File.dirname(__FILE__) +
      "/../helpers/initial_migration_fixture.sql"))
  end

  before(:all) do
    require "integrity/migrations"
  end

  before(:each) do
    [Project, Build, Commit, Notifier].each{ |i| i.auto_migrate_down! }
    database_adapter.execute("DROP TABLE migration_info")
    assert !table_exists?("migration_info") # just to be sure
  end

  test "upgrading a pre migration database" do
    capture_stdout { Integrity.migrate_db }

    current_migrations.should == ["initial", "add_commits", "add_enabled_column",
      "nil_commit_metadata", "add_scm_column"]
    assert table_exists?("integrity_projects")
    assert table_exists?("integrity_builds")
    assert table_exists?("integrity_notifiers")
    assert table_exists?("integrity_commits")
  end

  test "migrating data up from initial to the last migration" do
    load_initial_migration_fixture
    capture_stdout { Integrity.migrate_db }

    current_migrations.should == ["initial", "add_commits", "add_enabled_column",
      "nil_commit_metadata", "add_scm_column"]

    sinatra = Project.first(:name => "Sinatra")
    sinatra.should have(1).commits
    sinatra.commits.first.should be_successful
    sinatra.commits.first.output.should =~ /sinatra/

    shout_bot = Project.first(:name => "Shout Bot")
    shout_bot.should have(1).commits
    shout_bot.commits.first.should be_failed
    shout_bot.commits.first.output.should =~ /shout-bot/
  end
end
