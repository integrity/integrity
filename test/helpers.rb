$:.unshift File.dirname(__FILE__) + "/../lib", File.dirname(__FILE__)

%w(test/unit
context
pending
matchy
storyteller
webrat/sinatra
rr
mocha
dm-sweatshop).each { |dependency|
  begin
    require dependency
  rescue LoadError => e
    puts "You're missing some gems required to run the tests."
    puts "Please run `rake test:setup`"
    puts "NOTE: You'll probably need to run that command as root or with sudo."

    puts "Thanks :)"
    puts

    raise
  end
}

begin
  require "ruby-debug"
  require "redgreen"
rescue LoadError
end

require "integrity"
require "helpers/expectations"
require "integrity/notifier/test/fixtures"

module TestHelper
  def ignore_logs!
    Integrity.config[:log] = "/tmp/integrity.test.log"
  end

  def capture_stdout
    output = StringIO.new
    $stdout = output
    yield
    $stdout = STDOUT
    output
  end

  def silence_warnings
    $VERBOSE, v = nil, $VERBOSE
    yield
  ensure
    $VERBOSE = v
  end
end

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end

  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper

  before(:all) do
    DataMapper.setup(:default, "sqlite3::memory:")
  end

  before(:each) do
    require "integrity/migrations"
    [Project, Build, Commit, Notifier].each(&:auto_migrate_down!)
    capture_stdout { Integrity.migrate_db }

    RR.reset

    Notifier.available.each { |n|
      Notifier.send(:remove_const, n.to_s.split(":").last.to_sym)
    }
    Integrity.instance_variable_set(:@config, nil)
    Integrity.instance_variable_set(:@notifiers, nil)
  end

  after(:each) do
    capture_stdout { Integrity::Migrations.migrate_down! }
  end
end
