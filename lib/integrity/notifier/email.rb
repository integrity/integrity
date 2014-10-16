begin
  require 'pony'
rescue LoadError => e
  warn "Install pony to use the Email notifier: #{e.class}: #{e.message}"
  raise
end

module Integrity
  class Notifier
    class Email < Notifier::Base
      attr_reader :to, :from, :subject, :build, :previous_build, :previous_build_set, :only_success_changed
      alias_method :body, :full_message

      def initialize(build, config = {})
        super(build, config)
        configure_mailer
        set_delivery_options
        set_build_options
      end

      def deliver!
        Pony.mail(delivery_options) if should_deliver?
      end

      def delivery_options
        {to: to, from: from, body: body, subject: subject}
      end

      private

      def configure_mailer
        return configure_sendmail unless @config[:sendmail].blank?
        configure_smtp
      end

      def configure_smtp
        user = @config[:user].presence
        pass = @config[:pass].presence

        options = {
          address:              @config[:host],
          port:                 @config[:port],
          enable_starttls_auto: @config[:starttls],
          user_name:            user,
          password:             pass,
          authentication:       @config[:auth],
          domain:               helo_hostname,
        }

        Pony.options = {via: :smtp, via_options: options}
      end

      def helo_hostname
        domain = @config[:domain]
        if domain && !domain.empty?
          domain
        else
          Socket.gethostname
        end
      end

      def configure_sendmail
        options = {location: @config[:sendmail]}
        Pony.options = {via: :sendmail, via_options: options}
      end

      ##
      # Returns true if email should be sent. This is determined
      # if emails are configured to be sent after every build, or
      # the flag to only send email when success status changed
      # and the last build changed the status.
      def should_deliver?
        always_deliver? || success_changed?
      end

      ##
      # Returns true is configuration flag to only send email
      # if the last build caused the project status to change
      # from successful to failing. If flag is set to false,
      # then emails should be sent after every build.
      def only_deliver_if_success_changed?
        @only_success_changed
      end

      ##
      # Returns true if configuration flag to only send email
      # if the last build caused the project status to change
      # is set to false. If the setting is false, then emails
      # should be sent after every build.
      def always_deliver?
        not only_deliver_if_success_changed?
      end

      ##
      # Returns true if the last build caused the project status
      # to change from successful to failing.
      def success_changed?
        set_previous_build! unless @previous_build_set
        return true unless @previous_build.is_a?(Integrity::Build) # no previous build
        return @previous_build.successful? != @build.successful?
      end

      def set_previous_build!
        @previous_build = @build.project.sorted_builds.at(1)
        @previous_build_set = true
      end

      def set_delivery_options
        @to      = @config[:to]
        @from    = @config[:from]
        @subject = "[Integrity] #{build.project.name}: #{short_message}"
      end

      def set_build_options
        @previous_build_set = false
        @only_success_changed = (@config[:only_success_changed].to_s == '1')
      end
    end

    register Email
  end
end
