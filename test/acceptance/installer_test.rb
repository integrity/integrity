require File.dirname(__FILE__) + "/../helpers"

require "installer"

class InstallerTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to install Integrity
    Because I am lazy
  EOS

  before do
    @config_path   = "/tmp/integrity-test.yml"
    @database_path = "/tmp/integrity-test.db"

    config = File.read(Integrity.root / "config/config.sample.yml")
    config.gsub!(%r(sqlite3:///var/integrity.db), "sqlite3://#{@database_path}")
    File.open(@config_path, "w") { |f| f << config }
  end

  after do
    rm @database_path if File.exists?(@database_path)
  end

  scenario "running #create_db creates and migrates the database specified in config" do
    Installer.new.create_db(@config_path)

    `echo .schema | sqlite3 #{@database_path}`.tap do |schema|
      schema.should =~ /integrity_notifiers/
      schema.should =~ /integrity_projects/
      schema.should =~ /integrity_builds/
      schema.should =~ /integrity_commits/
    end
  end
end
