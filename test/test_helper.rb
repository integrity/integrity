require File.dirname(__FILE__) + "/../lib/integrity"
$LOAD_PATH << File.dirname(__FILE__) + "/helpers"

require "ruby-debug"
require "test/unit"
require "redgreen"
require "context"
require "matchy"
require "rr"
require "mocha"
require "test_fixtures"
require "expectations"

require "sinatra"
require "sinatra/test/unit"
require Integrity.root / "app"
require "webrat/sinatra"
require "acceptance_test_setup"

module TestHelper
  def setup_and_reset_database!
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.auto_migrate!
  end
  
  def ignore_logs!
    stub(Integrity).log { nil }
  end

  def response
    @response
  end
end

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end

  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper
end

module AcceptanceHelper
  def enable_auth!
    Integrity.config[:use_basic_auth]      = true
    Integrity.config[:admin_username]      = "admin"
    Integrity.config[:admin_password]      = "test"
    Integrity.config[:hash_admin_password] = false
  end
  
  def disable_auth!
    Integrity.config[:use_basic_auth] = false
  end
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  class << self
    alias :scenario :test
  end

  include AcceptanceHelper
  include WebratIntegrationHelper
  include PrettyStoryPrintingHelper
end
