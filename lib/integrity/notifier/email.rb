require 'diddies/mailer'

module Integrity
  class Notifier
    class Email < Notifier::Base
      attr_reader :to, :from

      def initialize(build, config={})
        @to     = config.delete("to")
        @from   = config.delete("from")
        super
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
        "[Integrity] #{build.project.name}: #{short_message}"
      end

      alias :body :full_message
      
      private

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
