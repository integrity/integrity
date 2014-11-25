begin
  require "postmark"
rescue LoadError => e
  warn "Install postmark to use the Postmark Email notifier: #{e.class}: #{e.message}"
  raise
end

module Integrity
  class Notifier
    class Postmark < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "postmark_api_key" } API KEY
  %input.text#postmark_api_key{                     |
    :name => "notifiers[Postmark][api_key]",        |
    :type => "text",                                |
    :value => config["api_key"] ||                  |
      "" }                                          |
%p.normal
  %label{ :for => "from_email_address" } FROM
  %input.text#from_email_address{                   |
    :name => "notifiers[Postmark][from_address]",   |
    :type => "text",                                |
    :value => config["from_address"] ||             |
      "" }                                          |
%p.normal
  %label{ :for => "to_email_address" } TO
  %input.text#to_email_address{                     |
    :name => "notifiers[Postmark][to_address]",     |
    :type => "text",                                |
    :value => config["to_address"] ||               |
      "" }                                          |
        HAML
      end

      def initialize(build, config={})
        @api_key        = config['api_key']
        @from_address   = config["from_address"]
        @to_address     = config["to_address"]
        super(build, config)
      end

      def deliver!
        client = ::Postmark::ApiClient.new(@api_key)

        client.deliver(from:        @from_address,
                       to:          @to_address,
                       subject:     subject,
                       text_body:   body)
      end

      def subject
        if build.successful?
          "[PASS] #{build.project.name}: #{short_message}"
        else
          "[FAILED] #{build.project.name}: #{short_message}"
        end
      end

      alias_method :body, :full_message
    end
  end
end
