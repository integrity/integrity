require "smtp-tls"
require "mailer"

module Integrity
  class Notifier
    class Email
      def self.notify_of_build(build, config)
        new(build, config).deliver!
      end
      
      def self.to_haml
        File.read __FILE__.gsub(/rb$/, "haml")
      end

      attr_reader :build, :to, :from

      def initialize(build, config={})
        @to     = config.delete("to")
        @from   = config.delete("from")
        @config = config
        @build  = build
        configure_mailer
      end

      def deliver!
        email.deliver!
      end

      def email
        @email ||= Sinatra::Mailer::Email.new(
          :to => to,
          :from => from,
          :text => body,
          :subject => subject
        )
      end

      def subject
        "[Integrity] #{build.project.name} build #{build.short_commit_identifier}: #{build.status.to_s.upcase}"
      end

      def body
        <<-EOM
Build #{build.commit_identifier} #{build.successful? ? "was successful" : "failed"}

Commit Message: #{build.commit_message}
Commit Date: #{build.commited_at}
Commit Author: #{build.commit_author.name}

Link: http://localhost:4567/#{build.project.permalink}/builds/#{build.commit_identifier}

Build Output:

#{build.output}
EOM
      end
      
      def configure_mailer
        Sinatra::Mailer.delivery_method = "net_smtp"
        Sinatra::Mailer.config = {
          :host => @config["host"],
          :port => @config["port"],
          :user => @config["user"],
          :pass => @config["pass"],
          :auth => @config["auth"]
        }
      end
    end
  end
end
