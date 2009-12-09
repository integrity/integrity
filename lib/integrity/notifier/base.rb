module Integrity
  class Notifier
    class Base
      def self.notify_of_build(build, config)
        Integrity.log "Notifying of build #{build.commit.short_identifier} with #{to_s}"
        Timeout.timeout(8) { new(build, config).deliver! }
      rescue Timeout::Error
        Integrity.log "#{to_s} notifier timed out"
        false
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
        build.human_status
      end

      def full_message
        <<-EOM
== #{short_message}

Commit Message: #{build.commit.message}
Commit Date: #{build.commit.committed_at}
Commit Author: #{build.commit.author.name}

Link: #{build_url}

== Build Output:

#{escape(build.output)}
EOM
      end

      def build_url
        base_url = Integrity.base_url ||
          Addressable::URI.parse("http://example.org")
        base_url.join("/#{build.project.permalink}/builds/#{build.id}")
      end

      private

        def escape(s)
          s.gsub("\e[0m", "").gsub(/\e\[3[1-7]m/, "")
        end
    end
  end
end
