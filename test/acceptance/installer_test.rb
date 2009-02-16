require File.dirname(__FILE__) + "/helpers"
require Integrity.root / "lib" / "integrity" / "installer"

class InstallerTest < Test::Unit::AcceptanceTestCase
  include FileUtils

  story <<-EOS
    As an user,
    I want to easily install Integrity
    So that I can spend time actually writing code
  EOS

  after(:all) do
    rm_rf install_directory
  end

  def install_directory
    install_directory = File.expand_path(File.dirname(__FILE__) + "/i-haz-integrity")
  end

  scenario "Installing integrity into directory" do
    output, _ = util_capture { Installer.new.install(install_directory) }

    assert File.directory?(install_directory + "/builds")
    assert File.directory?(install_directory + "/log")
    assert File.directory?(install_directory + "/public")
    assert File.directory?(install_directory + "/tmp")

    assert File.file?(install_directory + "/config.ru")

    YAML.load_file(install_directory + "/config.yml").tap { |config|
      config[:database_uri].should     be("sqlite3://#{install_directory}/integrity.db")
      config[:export_directory].should be(install_directory + "/builds")
      config[:log].should              be(install_directory + "/log/integrity.log")
    }

    YAML.load_file(install_directory + "/thin.yml").tap { |config|
      config["chdir"].should  be(install_directory)
      config["pid"].should    be(install_directory + "/thin.pid")
      config["rackup"].should be(install_directory + "/config.ru")
      config["log"].should    be(install_directory + "/log/thin.log")
    }

    output.should =~ /Awesome/
  end
end
