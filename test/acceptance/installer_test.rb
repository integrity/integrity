require File.dirname(__FILE__) + "/helpers"
require "integrity/installer"

class InstallerTest < Test::Unit::AcceptanceTestCase
  include FileUtils

  story <<-EOS
    As an user,
    I want to easily install Integrity
    So that I can spend time actually writing code
  EOS

  before(:each) do
    rm_rf root if File.directory?(root)
  end

  def root
    Pathname("/tmp/i-haz-integrity")
  end

  def install(options={})
    installer = Installer.new
    installer.options = { :passenger => false, :thin => false }.merge!(options)
    stdout, _ = util_capture { installer.install(root.to_s) }
    stdout
  end

  scenario "Installing integrity into a given directory" do
    assert install.include?("Awesome")

    assert root.join("builds").directory?
    assert root.join("log").directory?
    assert ! root.join("public").directory?
    assert ! root.join("tmp").directory?

    assert ! root.join("thin.yml").file?
    assert root.join("config.ru").file?

    config = YAML.load_file(root.join("config.yml"))

    config[:export_directory].should == root.join("builds").to_s
    config[:database_uri].should == "sqlite3://#{root}/integrity.db"
    config[:log].should          == root.join("log/integrity.log").to_s
  end

  scenario "Installing integrity for Passenger" do
    install(:passenger => true)

    assert root.join("public").directory?
    assert root.join("tmp").directory?
  end

  scenario "Installing Integrity for Thin" do
    install(:thin => true)

    config = YAML.load_file(root.join("thin.yml"))
    config["chdir"].should  == root.to_s
    config["pid"].should    == root.join("thin.pid").to_s
    config["rackup"].should == root.join("config.ru").to_s
    config["log"].should    == root.join("log/thin.log").to_s
  end
end
