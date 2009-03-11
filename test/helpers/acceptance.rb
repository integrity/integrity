require "helpers/acceptance/git_helper"

module AcceptanceHelper
  include FileUtils

  def export_directory
    File.dirname(__FILE__) + "/../../exports"
  end

  def enable_auth!
    Integrity.config[:use_basic_auth]      = true
    Integrity.config[:admin_username]      = "admin"
    Integrity.config[:admin_password]      = "test"
    Integrity.config[:hash_admin_password] = false
  end

  def login_as(user, password)
    def AcceptanceHelper.logged_in; true; end
    basic_auth user, password
    visit "/login"
    Integrity::App.before { login_required if AcceptanceHelper.logged_in }
  end

  def log_out
    def AcceptanceHelper.logged_in; false; end
    @_webrat_session = Webrat::SinatraSession.new(self)
  end

  def disable_auth!
    Integrity.config[:use_basic_auth] = false
  end

  def set_and_create_export_directory!
    FileUtils.rm_r(export_directory) if File.directory?(export_directory)
    FileUtils.mkdir(export_directory)
    Integrity.config[:export_directory] = export_directory
  end

  def setup_log!
    log_file = Pathname(File.dirname(__FILE__) + "/../../integrity.log")
    log_file.delete if log_file.exist?
    Integrity.config[:log] = log_file
  end
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  include AcceptanceHelper
  include Test::Storyteller
  include GitHelper
  include Webrat::Methods
  include Webrat::Matchers
  include Webrat::HaveTagMatcher

  # TODO: does this belongs in Webrat::SinatraSession?
  Webrat::Methods.delegate_to_session :response_code

  def app
    Integrity::App.tap { |app|
      app.set     :environment, :test
      app.disable :raise_errors, :run, :reload
    }
  end

  before(:all) do
    Integrity.config[:base_uri] = "http://www.example.com"
  end

  before(:each) do
    # ensure each scenario is run in a clean sandbox
    enable_auth!
    setup_log!
    set_and_create_export_directory!
    log_out
  end

  after(:each) do
    destroy_all_git_repos
    rm_r export_directory if File.directory?(export_directory)
  end

end
