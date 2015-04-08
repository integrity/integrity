module Integrity
  class Notifier
    class Base

      attr_reader :build

      delegate :repo, :sha1, to: :build, alow_nil: true

      def initialize(build, config)
        @build  = build
        @config = config.symbolize_keys
      end

      ## Class Methods ==============

      def self.notify(build, config)
        msg = "Notifying of build #{build.sha1_short} with #{to_s}"
        log_and_notify_with_timeout(msg) { new(build, config).deliver! }
      end

      def self.notify_of_build_start(build, config)
        notifier = new(build, config)
        if notifier.respond_to?(:deliver_started_notification!)
          msg = "Notifying of the start of build #{build.sha1_short} with #{to_s}"
          log_and_notify_with_timeout(msg) { notifier.deliver_started_notification! }
        end
      end

      def self.to_haml
        name = self.name.underscore.split('/').last.to_sym
        raise NotImplementedError, 'you need to call this method on your notifier' if name == :base
        @haml ||= File.read(File.dirname(__FILE__) + "/templates/#{name}.haml")
      end

      ## Instance Methods ==============

      def deliver!
        raise NotImplementedError, 'you need to implement this method in your notifier'
      end

      def short_message
        @build.human_status
      end

      def full_message
        I18n.translate(message_namespace, message_locals)
      end

      private

      def build_url
        "#{Integrity.config.base_url}/#{@build.url}"
      end

      def build_output
        escape(@build.output)
      end

      def commit_date
        @build.committed_at.in_time_zone('Pacific Time (US & Canada)')
      end

      def message_namespace
        :'notifier.base.message'
      end

      def message_locals
        {
          short_message: short_message,
          message: @build.message,
          commit_date: commit_date,
          author: @build.author,
          build_url: build_url,
          build_output: build_output
        }
      end

      def escape(s)
        s.gsub("\e[0m", '').gsub(/\e\[3[1-7]m/, '')
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
