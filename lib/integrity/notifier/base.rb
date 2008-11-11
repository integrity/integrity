module Integrity
  class Notifier
    class Base
      def self.notify_of_build(build, config)
        new(build, config).deliver!
      end

      def self.to_haml
        filename = name.split("::").last.downcase
        File.read File.join(Integrity.root / "lib" / "integrity" / "notifier" / "#{filename}.haml")
      end
      
      attr_reader :build
      
      def initialize(build, config)
        @build = build
        @config = config
      end
      
      def deliver!
        raise NoMethodError, "you need to implement this method in your notifier"
      end
      
      def short_message
        "Build #{build.short_commit_identifier} #{build.successful? ? "was successful" : "failed"}"
      end
      
      def full_message
        <<-EOM
"Build #{build.commit_identifier} #{build.successful? ? "was successful" : "failed"}"

Commit Message: #{build.commit_message}
Commit Date: #{build.commited_at}
Commit Author: #{build.commit_author.name}

Link: #{build_url}

Build Output:

#{stripped_build_output}
EOM
      end
      
      def build_url
        Integrity.config[:base_url] / build.project.permalink / "builds" / build.commit_identifier
      end

      private

        def stripped_build_output
          build.output.gsub("\e[0m", '').gsub(/\e\[3[1-7]m/, '')
        end
    end
  end
end
