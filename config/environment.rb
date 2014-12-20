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
