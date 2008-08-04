module Integrity
  module Notifier
  end
end

Dir["#{File.dirname(__FILE__)}/notifier/*.rb"].each &method(:require)
