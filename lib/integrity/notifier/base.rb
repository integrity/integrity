module Integrity
  class Notifier
    class Base
      def self.notify_of_build(build, config)
        Integrity.log "Notifying of build #{build.commit.short_identifier} using the #{to_s} notifier"
        Timeout.timeout(8) { new(build.commit, config).deliver! }
      rescue Timeout::Error
        Integrity.log "#{to_s} notifier timed out"
        false
      end

      def self.to_haml
        raise NotImplementedError, "you need to implement this method in your notifier"
      end

      attr_reader :commit

      def initialize(commit, config)
        @commit = commit
        @config = config
      end

      def deliver!
        raise NotImplementedError, "you need to implement this method in your notifier"
      end

      def short_message
        commit.human_readable_status
      end

      def full_message
        <<-EOM
"Build #{commit.identifier} #{commit.successful? ? "was successful" : "failed"}"

Commit Message: #{commit.message}
Commit Date: #{commit.committed_at}
Commit Author: #{commit.author.name}

Link: #{commit_url}

Build Output:

#{stripped_commit_output}
EOM
      end

      def commit_url
        raise if Integrity.config[:base_uri].nil?
        Integrity.config[:base_uri] / commit.project.permalink / "commits" / commit.identifier
      end

      private

        def stripped_commit_output
          commit.output.gsub("\e[0m", "").gsub(/\e\[3[1-7]m/, "")
        end
    end
  end
end
