begin
  require "tinder"
rescue LoadError
  abort "Install tinder to use the Campfire notifier"
end

module Integrity
  class Notifier
    class Campfire < Notifier::Base
      attr_reader :config

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/campfire.haml")
      end

      def deliver!
        room.speak "#{short_message}. #{build_url}" if announce_build?
        room.paste full_message if build.failed?
        room.leave
      end

    private
      def room
        @room ||= begin
          options = {}
          options[:ssl] = config["use_ssl"] ? true : false
          campfire = Tinder::Campfire.new(config["account"], options)
          campfire.login(config["user"], config["pass"])
          campfire.find_room_by_name(config["room"])
        end
      end

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
