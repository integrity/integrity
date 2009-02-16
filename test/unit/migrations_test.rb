require File.dirname(__FILE__) + "/../helpers"

class MigrationsTest < Test::Unit::TestCase
  def table_exists?(table_name)
    database_adapter.storage_exists?(table_name)
  end

  def database_adapter
    DataMapper.repository(:default).adapter
  end

  before(:all) do
    require "integrity/migrations"
  end

  before(:each) do
    [Project, Build, Commit, Notifier].each(&:auto_migrate_down!)
  end

  test "migrating up for the first time creates the database up to last migration" do
    assert !table_exists?("migration_info")
    Integrity.migrate("up")

    database_adapter.query("SELECT * from migration_info").
      should == ["initial", "add_commits"]
    assert table_exists?("integrity_projects")
    assert table_exists?("integrity_builds")
    assert table_exists?("integrity_notifiers")
    assert table_exists?("integrity_commits")
  end

  context "Migrating a pre migration database" do
    it "creates the migration_info table" do
      [Project, Build, Notifier].each(&:auto_migrate!)
      assert !table_exists?("migration_info")
      assert !table_exists?("integrity_commits")

      Integrity.migrate("up")

      assert table_exists?("migration_info")
      database_adapter.query("SELECT * from migration_info").should == ["initial"]
    end

    it "migrates the data as well" do
      pending "42"
    end
  end
end
