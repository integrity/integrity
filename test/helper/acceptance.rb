require "storyteller"
require "webrat"
require "rack/test"
require "webmock"

require "helper"
require "helper/acceptance/repo"

Rack::Test::DEFAULT_HOST.replace("www.example.com")

module AcceptanceHelper
  include IntegrityTest

  def git_repo(name)
    GitRepo.new(name.to_s).tap { |repo|
      repo.create unless File.directory?(repo.uri)
    }
  end

  def login_as(user, password)
    def AcceptanceHelper.logged_in; true; end
    rack_test_session.basic_authorize(user, password)
    Integrity::App.before { login_required if AcceptanceHelper.logged_in }
  end

  def log_out
    def AcceptanceHelper.logged_in; false; end
    rack_test_session.header("Authorization", nil)
  end
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  include FileUtils
  include AcceptanceHelper
  include Test::Storyteller

  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
  include Webrat::HaveTagMatcher
  include WebMock

  Webrat::Methods.delegate_to_session :response_code

  attr_reader :app

  before(:all) do
    Integrity::App.set(:environment, :test)
    Webrat.configure { |c| c.mode = :rack }
    Integrity.configure { |c|
      c.github_token "SECRET"
    }
    Integrity.builder = lambda { |build| Builder.new(build).build }
    @app = Integrity.app
  end

  before(:each) do
    Integrity.directory.mkdir
    log_out
  end

  after(:each) do
    Integrity.directory.rmtree
  end
end
