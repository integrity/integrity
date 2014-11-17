begin 
  require "shout-bot"
rescue LoadError => e
  warn "Install shout-bot to use the IRC notifier: #{e.class}: #{e.message}"
  raise
end

module Integrity
  class Notifier
    class IRC < Notifier::Base
      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/irc.haml")
      end

      def initialize(build, config={})
        @uri = config["uri"]
        super
      end

      def deliver!
        ShoutBot.shout(@uri) do |channel|
          channel.say "#{build.project.name}: #{short_message}"
        end
      end
    end
  end
end
