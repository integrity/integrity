require "smtp-tls"
require "mailer"

module Integrity
  module Notifier
    class Email
      def self.notify_of_build(build)
        new(build, Integrity.config[:email]).deliver!
      end
      
      attr_reader :build, :to, :from
      
      def initialize(build, options={})
        Sinatra::Mailer.config = options[:config]
        Sinatra::Mailer.delivery_method = options[:delivery_method]
        @to    = options[:to]
        @from  = options[:from]
        @build = build
      end
      
      def deliver!
        email.deliver!
      end
      
      def email
        @email ||= Sinatra::Mailer::Email.new(
          :to => to, 
          :from => from, 
          :text => email_body, 
          :subject => email_subject
        )
      end
      
      def email_subject
        "[Integrity] #{build.project.name} build #{build.short_commit_identifier}: #{build.status.to_s.upcase}"
      end
      
      def email_body
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
    end
  end
end
