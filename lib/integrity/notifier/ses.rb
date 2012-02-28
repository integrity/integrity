begin
  require 'aws/ses'
rescue LoadError => e
  warn "Install aws-ses to use the SES Email notifier: #{e.class}: #{e.message}"
  raise
end

module Integrity
  class Notifier
    class SES < Notifier::Base
      attr_reader :from, :ses, :to

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/ses.haml")
      end

      def initialize(build, config={})
        @from = config["from"]
        @ses  = AWS::SES::Base.new(
          :access_key_id  => config['access_key_id'],
          :secret_access_key => config['secret_access_key']
        )
        @to   = config["to"]
        super(build, config)
      end

      def deliver!
        ses.send_email(
          :to => to, 
          :from => from, 
          :subject => subject,
          :body => body
        )
      end

      def subject
        "[Integrity] #{build.project.name}: #{short_message}"
      end

      alias_method :body, :full_message

    end

    register SES
  end
end
