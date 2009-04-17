require File.dirname(__FILE__) + "/../helpers/acceptance"
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

  def install(option="")
    installer = File.dirname(__FILE__) + "/../../bin/integrity"
    IO.popen("#{installer} install #{root} #{option}".strip).read
  end

  scenario "Installing integrity into a given directory" do
    post_install_message = install

    assert post_install_message.include?("Awesome")
    assert post_install_message.include?("integrity migrate_db #{root.join("config.yml")}")

    assert root.join("builds").directory?
    assert root.join("log").directory?
    assert ! root.join("public").directory?
    assert ! root.join("tmp").directory?

    assert ! root.join("Rakefile").file?
    assert ! root.join("integrity.rb").file?
    assert ! root.join(".gems").file?

    assert ! root.join("thin.yml").file?
    assert root.join("config.ru").file?

    config = YAML.load_file(root.join("config.yml"))

    config[:export_directory].should == root.join("builds").to_s
    config[:database_uri].should == "sqlite3://#{root}/integrity.db"
    config[:log].should          == root.join("log/integrity.log").to_s
  end

  scenario "Installing integrity for Passenger" do
    install("--passenger")

    assert root.join("public").directory?
    assert root.join("tmp").directory?

    assert ! root.join("thin.yml").file?
  end

  scenario "Installing Integrity for Thin" do
    install("--thin")

    config = YAML.load_file(root.join("thin.yml"))
    config["chdir"].should  == root.to_s
    config["pid"].should    == root.join("thin.pid").to_s
    config["rackup"].should == root.join("config.ru").to_s
    config["log"].should    == root.join("log/thin.log").to_s
  end

  scenario "Installing Integrity for Heroku" do
    message = install("--heroku")

    assert_equal "integrity --version 0.1.9.3", root.join(".gems").read.chomp

    assert root.join("Rakefile").file?
    assert root.join("integrity-config.rb").file?
    assert root.join("config.ru").file?

    assert message.include?("ready to be deployed onto Heroku")
  end
end
