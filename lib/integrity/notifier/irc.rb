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
        <<-HAML
%p.normal
  %label{ :for => "irc_notifier_uri" } Send to
  %input.text#irc_notifier_uri{ |
    :name => "notifiers[IRC][uri]", |
    :type => "text", |
    :value => config["uri"] || |
      "irc://ci-bot@irc.freenode.net:6667/#example" } |
HAML
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
    
    register IRC
  end
end
