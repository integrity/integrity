begin
  require "shout-bot"
rescue LoadError
  abort "Install shout-bot to use the IRC notifier"
end

module Integrity
  class Notifier
    class IRC < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "irc_notifier_uri" } Send to
  %input.text#irc_notifier_uri{                          |
    :name => "notifiers[IRC][uri]",                      |
    :type => "text",                                     |
    :value => config["uri"] ||                           |
      "irc://IntegrityBot@irc.freenode.net:6667/#test" } |
        HAML
      end

      def initialize(build, config={})
        @uri = config.delete("uri")
        super
      end

      def deliver!
        ShoutBot.shout(@uri) do |channel|
          channel.say "#{build.project.name}: #{short_message} | #{build_url}"
        end
      end
    end

    register IRC
  end
end
