begin
  require "broach"
rescue LoadError
  abort "Install broach to use the Campfire notifier"
end

module Integrity
  class Notifier
    class Campfire < Notifier::Base
      attr_reader :config

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/campfire.haml")
      end

      def deliver!
        Broach.settings = config
        Broach.speak(config["room"], "#{short_message}. #{build_url}") if announce_build?
        Broach.speak(config["room"], full_message, :type => :paste) if build.failed?
      end

    private
      def full_message
        <<-EOM
Commit Message: #{build.commit.message}
Commit Date: #{build.commit.committed_at}
Commit Author: #{build.commit.author.name}

#{escape(build.output)}
EOM
      end

      def announce_build?
        build.failed? || config["announce_success"]
      end
    end

    register Campfire
  end
end
