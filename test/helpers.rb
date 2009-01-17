require File.dirname(__FILE__) + "/../lib/integrity"

begin
  require "test/unit"
  require "redgreen"
  require "context"
  require "storyteller"
  require "pending"
  require "matchy"
  require "rr"
  require "mocha"
  require "ruby-debug"
rescue LoadError
  puts "You're missing some gems required to run the tests."
  puts "Please run `rake test:install_dependencies`"
  puts 
  puts "Thanks :)"
  puts
  
  exit 1
end

require File.dirname(__FILE__) / "helpers" / "expectations"
require File.dirname(__FILE__) / "helpers" / "fixtures"
require File.dirname(__FILE__) / "helpers" / "acceptance"

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

