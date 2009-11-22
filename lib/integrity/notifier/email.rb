begin
  require "sinatra/ditties/mailer"
rescue LoadError
  abort "Install sinatra-ditties to use the Email notifier"
end

module Integrity
  class Notifier
    class Email < Notifier::Base
      attr_reader :to, :from

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/email.haml")
      end

      def initialize(build, config={})
        @to     = config.delete("to")
        @from   = config.delete("from")
        super(build, config)
        configure_mailer
      end

      def deliver!
        email.deliver!
      end

      def email
        @email ||= Sinatra::Mailer::Email.new(
          :to       => to,
          :from     => from,
          :text     => body,
          :subject  => subject
        )
      end

      def subject
        "[Integrity] #{build.project.name}: #{short_message}"
      end

      alias_method :body, :full_message

      private
        def configure_mailer
          return configure_sendmail unless @config["sendmail"].blank?
          configure_smtp
        end

        def configure_smtp
          user = @config["user"] || ""
          pass = @config["pass"] || ""
          user = nil if user.empty?
          pass = nil if pass.empty?

          Sinatra::Mailer.delivery_method = "net_smtp"

          Sinatra::Mailer.config = {
            :host => @config["host"],
            :port => @config["port"],
            :user => user,
            :pass => pass,
            :auth => @config["auth"],
            :domain => @config["domain"]
          }
        end

        def configure_sendmail
          Sinatra::Mailer.delivery_method = :sendmail
          Sinatra::Mailer.config = {:sendmail_path => @config['sendmail']}
        end
    end

    register Email
  end
end
