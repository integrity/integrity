require "webrat/sinatra"
require Integrity.root / "app"
require File.dirname(__FILE__) / "acceptance/git_helper"

Webrat.configuration.mode = :sinatra

module AcceptanceHelper
  include FileUtils

  def export_directory
    Integrity.root / "exports"
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
    Sinatra.application.before { login_required if AcceptanceHelper.logged_in }
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
    pathname = Integrity.root / "integrity.log"
    FileUtils.rm pathname if File.exists?(pathname)
    Integrity.config[:log] = pathname
  end
end

module WebratHelpers
  include Webrat::Methods
  Webrat::Methods.delegate_to_session :response_code, :response_body
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  include AcceptanceHelper
  include Test::Storyteller
  include WebratHelpers
  include GitHelper
  
  before(:each) do
    # ensure each scenario is run in a clean sandbox
    setup_and_reset_database!
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
