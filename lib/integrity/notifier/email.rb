begin
  require "pony"
rescue LoadError => e
  warn "Install pony to use the Email notifier: #{e.class}: #{e.message}"
  raise
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
        Pony.mail(
          :to      => to,
          :from    => from,
          :body    => body,
          :subject => subject
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

          options = {
            :address              => @config["host"],
            :port                 => @config["port"],
            :enable_starttls_auto => @config["starttls"],
            :user_name            => user,
            :password             => pass,
            :authentication       => @config["auth"],
            :domain               => @config["domain"]
          }

          Pony.options = { :via => :smtp, :via_options => options }
        end

        def configure_sendmail
          options = { :location => @config["sendmail"] }
          Pony.options = { :via => :sendmail, :via_options => options }
        end
    end

    register Email
  end
end
