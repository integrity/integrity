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

Link: #{Integrity.config[:base_url]}/#{build.project.permalink}/builds/#{build.commit_identifier}
          
Build Output:

#{stripped_build_output}
        email
      end

      private
        def stripped_build_output
          build.output.gsub("\e[0m", '').gsub(/\e\[3[1-7]m/, '')
        end
    end
  end
end
