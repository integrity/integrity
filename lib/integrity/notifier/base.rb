module Integrity
  class Notifier
    class Base
      def self.notify_of_build(build, config)
        Timeout.timeout(8) { new(build, config).deliver! }
      end

      def self.to_haml
        raise NoMethodError, "you need to implement this method in your notifier"
      end

      attr_reader :commit

      def initialize(commit, config)
        @commit = commit
        @config = config
      end

      def build
        warn "Notifier::Base#build is deprecated, use Notifier::Base#commit instead (#{caller[0]})"
        commit
      end

      def deliver!
        raise NoMethodError, "you need to implement this method in your notifier"
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

        def stripped_build_output
          warn "Notifier::Base#stripped_build_output is deprecated, use Notifier::base#stripped_commit_output instead (#{caller[0]})"
          stripped_commit_output
        end
    end
  end
end
