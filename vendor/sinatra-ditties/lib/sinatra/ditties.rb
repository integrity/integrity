require "sinatra/base"

module Sinatra
  module Ditties
    def self.version
      "0.0.2".freeze
    end
  end

  autoload :Authorization, File.dirname(__FILE__) + "/ditties/authorization"
  autoload :Mailer,        File.dirname(__FILE__) + "/ditties/mailer"
end
