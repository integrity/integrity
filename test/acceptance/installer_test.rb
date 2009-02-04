require File.dirname(__FILE__) + "/helpers"

require "integrity/installer"

class InstallerTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to install Integrity
    Because I am lazy
  EOS

  def table_exists?(table_name)
    database_adapter.storage_exists?(table_name)
  end

  def database_adapter
    DataMapper.repository(:default).adapter
  end

  before do
    @config_path   = "/tmp/integrity-test.yml"
    @database_path = "/tmp/integrity-test.db"

    config = File.read(Integrity.root / "config/config.sample.yml")
    config.gsub!(%r(sqlite3:///var/integrity.db), "sqlite3://#{@database_path}")
    File.open(@config_path, "w") { |f| f << config }
    rm @database_path if File.exists?(@database_path)
  end

  scenario "Running #create_db for the first time" do
    Installer.new.create_db(@config_path)

    database_adapter.query("SELECT * from migration_info").
      should == ["initial"]
    assert table_exists?("migration_info")
    assert table_exists?("integrity_projects")
    assert table_exists?("integrity_builds")
    assert table_exists?("integrity_notifiers")
    assert !table_exists?("integrity_commits") # just to be sure :)
  end

  scenario "Running #migrate_db on a pre-migrations database" do
    DataMapper.setup(:default, "sqlite3://:memory:")
    DataMapper.auto_migrate!

    assert table_exists?("integrity_projects")
    assert table_exists?("integrity_builds")
    assert table_exists?("integrity_notifiers")
    assert !table_exists?("integrity_commits")
    assert !table_exists?("migration_info")

    Installer.new.send(:migrate_db, "up", 1)

    assert table_exists?("migration_info")
  end
end
