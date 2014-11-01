module Integrity
  module Payload
    class Base
      def self.build(payload)
        new(payload).build
      end

      def initialize(payload)
        @payload = payload
      end

      def build
        PayloadBuilder.build(self)
      end

      def repo
        Repository.new(uri, branch)
      end

      def head
        commits.detect { |c| c[:identifier] == @payload["after"] }
      end

      def commits
        @commits ||= @payload["commits"].map { |commit|
          { :identifier   => commit["id"],
            :author       => normalize_author(commit["author"]),
            :message      => commit["message"],
            :committed_at => commit["timestamp"] }
        }
      end

      def branch
        @payload["ref"].split("refs/heads/").last
      end

      def normalize_author(author)
        "#{author["name"]} <#{author["email"]}>"
      end

      def deleted?
        false
      end
    end
  end
end
