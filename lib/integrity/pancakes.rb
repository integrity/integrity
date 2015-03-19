module Integrity
  module Pancakes
    def self.logger
      Integrity.logger
    end

    # LOGPancakes - ghetto tagged logging
    def self.logp(level, msg)
      logger.send(level, "[pancakes] #{msg}")
    end
  end
end

require 'integrity/pancakes/stack'
require 'integrity/pancakes/fleet_api_template_builder'
require 'integrity/pancakes/freezer'
