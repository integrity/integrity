require File.dirname(__FILE__) + "/helpers"
require Integrity.root.join("lib", "integrity", "installer")

class InstallerTest < Test::Unit::AcceptanceTestCase
  include FileUtils

  story <<-EOS
    As an user,
    I want to easily install Integrity
    So that I can spend time actually writing code
  EOS

  before(:each) do
    rm_rf install_directory if File.directory?(install_directory)
  end

  def install_directory
    install_directory = "/tmp/i-haz-integrity"
  end

  def install(options={})
    installer = Installer.new
    installer.options = { :passenger => false, :thin => false }.merge!(options)
    stdout, _ = util_capture { installer.install(install_directory) }
    stdout
  end

  scenario "Installing integrity into directory" do
    assert install.include?("Awesome")

    assert File.directory?(install_directory + "/builds")
    assert File.directory?(install_directory + "/log")
    assert ! File.directory?(install_directory + "/public")
    assert ! File.directory?(install_directory + "/tmp")

    assert ! File.file?(install_directory + "/thin.yml")
    assert File.file?(install_directory + "/config.ru")

    YAML.load_file(install_directory + "/config.yml").tap { |config|
      config[:database_uri].should     be("sqlite3://#{install_directory}/integrity.db")
      config[:export_directory].should be(install_directory + "/builds")
      config[:log].should              be(install_directory + "/log/integrity.log")
    }
  end

  scenario "Installing integrity for Passenger" do
    install(:passenger => true)

    assert File.directory?(install_directory + "/public")
    assert File.directory?(install_directory + "/tmp")
  end

  scenario "Installing Integrity for Thin" do
    install(:thin => true)

    YAML.load_file(install_directory + "/thin.yml").tap { |config|
      config["chdir"].should  be(install_directory)
      config["pid"].should    be(install_directory + "/thin.pid")
      config["rackup"].should be(install_directory + "/config.ru")
      config["log"].should    be(install_directory + "/log/thin.log")
    }
  end
end
