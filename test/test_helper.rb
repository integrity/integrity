require File.dirname(__FILE__) + "/../lib/integrity"
$LOAD_PATH << File.dirname(__FILE__) + "/helpers"

require "ruby-debug"
require "test/unit"
require "redgreen"
require "context"
require "matchy"
require "rr"
require "mocha"
require "sinatra"
require Integrity.root / "app"
require "sinatra/test/unit"
require "test_fixtures"
require "expectations"

module TestHelper
  def setup_and_reset_database!
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.auto_migrate!
  end
  
  def ignore_logs!
    stub(Integrity).log { nil }
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
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  include AcceptanceHelper
  
  class << self
    alias :scenario :test
  end
  
  def self.story(story=nil)
    @story = story if story
    @story
  end

  before :all do
    puts
    puts self.class.story.to_s.gsub(/^\s+/, '')
  end

  after :all do
    puts
  end
end