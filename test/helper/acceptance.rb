require "storyteller"
require "webrat"
require "rack/test"
require "bob/test"

require "helper"

Rack::Test::DEFAULT_HOST.replace("www.example.com")

module AcceptanceHelper
  include Bob::Test

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

class BuilderStub
  def initialize(buildable)
    @buildable = buildable
  end

  def build
    Integrity::ProjectBuilder.new(@buildable).build
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

  Webrat::Methods.delegate_to_session :response_code

  def app
    Rack::Builder.new {
      map "/github" do
        use Bobette::GitHub do
          ! Integrity.config.build_all?
        end

        run Bobette.new(Integrity::BuildableProject)
      end

      map "/" do
        use Rack::Lint
        run Integrity::App
      end
    }
  end

  before(:all) do
    Integrity::App.set(:environment, :test)
    Webrat.configure { |c| c.mode = :rack }
    Integrity.config.builder = ::BuilderStub
  end

  before(:each) do
    Integrity.config.directory.mkdir
    log_out
  end

  after(:each) do
    Integrity.config.directory.rmtree
  end
end
