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

  before(:all) do
    require "integrity/migrations"
  end

  before(:each) do
    [Project, Build, Commit, Notifier].each(&:auto_migrate_down!)
    assert !table_exists?("migration_info") # just to be sure
  end

  test "migrating up a pre migration database" do
    Integrity.migrate("up")

    current_migrations.should == ["initial", "add_commits"]
    assert table_exists?("integrity_projects")
    assert table_exists?("integrity_builds")
    assert table_exists?("integrity_notifiers")
    assert table_exists?("integrity_commits")
  end

  test "migrating down a pre migration database" do
    [Project, Build, Notifier].each(&:auto_migrate!)

    Integrity.migrate("down")

    # Initial migration is created but it gets removed just after
    # because we migrate down
    assert table_exists?("migration_info")
    current_migrations.should == []

    assert ! table_exists?("integrity_projects")
    assert ! table_exists?("integrity_builds")
    assert ! table_exists?("integrity_notifiers")
  end

  test "migrating data from initial up to add_commits migration" do
    pending
  end

  test "migrating data from migration down to initial migration" do
    pending
  end
end
