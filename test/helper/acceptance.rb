require "webrat"
require "rack/test"
require "webmock/test_unit"

require "helper"
require "helper/acceptance/repo"

Rack::Test::DEFAULT_HOST.replace("www.example.com")

# TODO
Webrat::Session.class_eval {
  def redirect?
    [301, 302, 303, 307].include?(response_code)
  end
}

module AcceptanceHelper
  include TestHelper

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

class Test::Unit::AcceptanceTestCase < IntegrityTest
  include FileUtils
  include AcceptanceHelper

  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
  include Webrat::HaveTagMatcher
  include WebMock

  Webrat::Methods.delegate_to_session :response_code

  attr_reader :app

  def self.story(*a); end

  class << self
    alias_method :scenario, :test
  end

  setup do
    Integrity::App.set(:environment, :test)
    Webrat.configure { |c| c.mode = :rack }
    Integrity.builder = lambda { |build| Builder.new(build).build }
    @app = Integrity.app
    Integrity.directory.mkdir
    log_out
  end

  teardown do
    Integrity.directory.rmtree
  end
end
