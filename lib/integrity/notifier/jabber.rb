require 'xmpp4r-simple'
require 'ruby-debug'

module Integrity
  class Notifier
    class Jabber
      def self.notify_of_build(build, config)
        new(build, config).deliver!
      end
        
      def self.to_haml
         File.read __FILE__.gsub(/rb$/, "haml")
      end
      
      attr_reader :build, :recipients

      def initialize(build, config = {})
        @server = ::Jabber::Simple.new(config.delete(:user), config.delete(:pass))
        @build = build
        @recipients = config[:recipients].nil? ? [] : config.delete(:recipients).split(/\s+/) 
      end

      def deliver!
        message_to_deliver = message
        @recipients.each do |r|
          @server.deliver(r, message_to_deliver)
        end
      end

      def message
<<-content
          Build #{build.commit_identifier} #{build.successful? ? "was successful" : "failed"} commited at #{build.commited_at} by #{build.commit_author.name}

          Commit Message: #{build.commit_message}
          
          Link: http://localhost:4567/#{build.project.permalink}/builds/#{build.commit_identifier}
content
      end
    end
  end
end