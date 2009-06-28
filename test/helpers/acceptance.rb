$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../../vendor/webrat/lib")

require File.dirname(__FILE__) + "/../helpers"

gem "foca-storyteller" if respond_to?(:gem)
require "storyteller"
require "webrat"
require "bob/test"

module AcceptanceHelper
  include Bob::Test

  def git_repo(name)
    GitRepo.new(name).tap(&:create)
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

    Webrat.configure { |c| c.mode = :sinatra }
  end

  before(:each) do
    Bob.directory = File.expand_path(File.dirname(__FILE__) + "/../tmp")
    Bob.engine    = Bob::Engine::Foreground
    Bob.logger    = Logger.new("/dev/null")

    Integrity.config = {
      :export_directory => Bob.directory,
      :base_uri         => "http://www.example.com",
      :use_basic_auth   => true,
      :admin_username   => "admin",
      :admin_password   => "test",
      :hash_admin_password => false
    }

    log_out
  end

  after(:each) do
    rm_r(Bob.directory) if File.directory?(Bob.directory)
  end
end
