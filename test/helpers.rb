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
    puts "Please run `rake test:install_dependencies`"
    puts "You'll probably need to run that command as root or with sudo."

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

  def util_capture
    output = StringIO.new
    $stdout = output
    yield
    $stdout = STDOUT
    output
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
    RR.reset
    DataMapper.auto_migrate!
    Integrity.instance_variable_set(:@config, nil)
    Notifier.available.each { |n|
      Notifier.send(:remove_const, n.to_s.split(":").last.to_sym)
    }

    repository(:default) do
      transaction = DataMapper::Transaction.new(repository)
      transaction.begin
      repository.adapter.push_transaction(transaction)
    end
  end

  after(:each) do
    repository(:default) do
      while repository.adapter.current_transaction
        repository.adapter.current_transaction.rollback
        repository.adapter.pop_transaction
      end
    end
  end
end
