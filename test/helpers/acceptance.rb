require File.dirname(__FILE__) + "/../helpers"

gem "foca-storyteller" if respond_to?(:gem)
require "storyteller"

require "bob/test"

module AcceptanceHelper
  include Bob::Test

  def git_repo(name)
    GitRepo.new(name).tap(&:create)
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

  def setup_log!
    log_file = Pathname(File.dirname(__FILE__) + "/../../integrity.log")
    log_file.delete if log_file.exist?
    Integrity.config[:log] = log_file
  end
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  include FileUtils
  include AcceptanceHelper
  include Test::Storyteller
  include Webrat::Methods
  include Webrat::Matchers
  include Webrat::HaveTagMatcher

  Webrat::Methods.delegate_to_session :response_code

  def app
    Integrity::App
  end

  before(:all) do
    app.set(:environment, :test)
  end

  before(:each) do
    # ensure each scenario is run in a clean sandbox
    Integrity.config[:export_directory] = Bob.directory
    Integrity.config[:base_uri] = "http://www.example.com"
    enable_auth!
    setup_log!
    log_out
  end

  after(:each) do
    rm_r(Bob.directory) if File.directory?(Bob.directory)
  end
end
