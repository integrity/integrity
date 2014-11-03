begin
  require "pony"
rescue LoadError => e
  warn "Install pony to use the Email notifier: #{e.class}: #{e.message}"
  raise
end

module Integrity
  class Notifier
    class Email < Notifier::Base
      attr_reader :to, :from, :build, :previous_build, :previous_build_set, :only_success_changed

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/email.haml")
      end

      def initialize(build, config={})
        @to     = config["to"]
        @from   = config["from"]
        @build  = build
        @only_success_changed = (config["only_success_changed"].to_s == "1")
        @previous_build_set = false

        super(@build, config)
        configure_mailer
      end

      def deliver!
        Pony.mail(
          :to      => to,
          :from    => from,
          :body    => body,
          :subject => subject
        ) if !@only_success_changed || success_changed?
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
            :domain               => helo_hostname,
          }

          Pony.options = { :via => :smtp, :via_options => options }
        end
        
        def helo_hostname
          domain = @config["domain"]
          if domain && !domain.empty?
            domain
          else
            Socket.gethostname
          end
        end

        def configure_sendmail
          options = { :location => @config["sendmail"] }
          Pony.options = { :via => :sendmail, :via_options => options }
        end

        def success_changed?
          set_previous_build! unless @previous_build_set
          return true unless @previous_build.is_a?(Integrity::Build) # no previous build
          return @previous_build.successful? != @build.successful?
        end

        def set_previous_build!
          @previous_build = @build.project.sorted_builds.at(1)
          @previous_build_set = true
        end
    end
  end
end
