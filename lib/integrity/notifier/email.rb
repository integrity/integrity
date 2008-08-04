require "smtp-tls"
require "mailer"

module Integrity
  module Notifier
    class Email
      def self.notify_of_build(build, config)
        new(build, config).deliver!
      end
      
      def self.to_haml
        File.read __FILE__.gsub(/rb$/, "haml")
      end

      attr_reader :build, :to, :from

      def initialize(build, config={})
        @config = config
        @to     = config[:to]
        @from   = config[:from]
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
        <<-email
Build #{build.commit_identifier} #{build.successful? ? "was successful" : "failed"}

Commit Message: #{build.commit_message}
Commit Date: #{build.commited_at}
Commit Author: #{build.commit_author.name}

Link: http://localhost:4567/#{build.project.permalink}/builds/#{build.commit_identifier}

Build Output:

#{build.output}
        email
      end
      
      def configure_mailer
        Sinatra::Mailer.delivery_method = "smtp"
        Sinatra::Mailer.config = { 
          :host => @config[:host], 
          :port => @config[:port], 
          :user => @config[:user], 
          :pass => @config[:password], 
          :auth => @config[:pass].to_sym 
        }
      end
    end
  end
end
