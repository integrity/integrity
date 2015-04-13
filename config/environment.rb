require './init.rb'
require 'daemons'

class Rails
  def self.root
    ::Integrity.root
  end

  def self.logger
    ::Integrity.logger
  end
end

# https://gist.github.com/robhurring/732327
RAILS_ROOT = File.expand_path('..', __FILE__)
puts 'loaded environment'
