module Integrity
  class Notifier
    class Base
      def self.notify(build, config)
        msg = "Notifying of build #{build.sha1_short} with #{to_s}"
        log_and_notify_with_timeout(msg) { new(build, config).deliver! }
      end

      def self.notify_of_build_start(build, config)
        notifier = new(build, config)
        if notifier.respond_to?(:deliver_started_notification!)
          msg = "Notifying of the start of build #{build.sha1_short} with #{to_s}"
          log_and_notify_with_timeout(msg) do
            notifier.deliver_started_notification!
          end
        end
      end

      def self.to_haml
        raise NotImplementedError, "you need to implement this method in your notifier"
      end

      attr_reader :build

      def initialize(build, config)
        @build  = build
        @config = config
      end

      def deliver!
        raise NotImplementedError, "you need to implement this method in your notifier"
      end

      def short_message
        @build.human_status
      end

      def full_message
        <<-EOM
== #{short_message}

Commit Message: #{@build.message}
Commit Date: #{@build.committed_at}
Commit Author: #{@build.author}

Link: #{build_url}

== Build Output:

#{build_output}
EOM
      end

      def build_url
        base_url = Integrity.config.base_url ||
          Addressable::URI.parse("http://example.org")
        base_url.join("/#{@build.project.permalink}/builds/#{@build.id}")
      end

      def build_output
        @build.output.gsub("\e[0m", "").gsub(/\e\[3[1-7]m/, "")
      end
      private

        def escape(s)
          s.gsub("\e[0m", "").gsub(/\e\[3[1-7]m/, "")
        end

        def self.log_and_notify_with_timeout(log_message, &block)
          Integrity.logger.info(log_message)
          Timeout.timeout(8) { yield }
        rescue Timeout::Error
          Integrity.logger.info("#{to_s} notifier timed out")
          false
        end
    end
  end
end
