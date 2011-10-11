begin
  require "notifo"
rescue LoadError => e
  warn "Install notifo to use the Notifo notifier: #{e.class}: #{e.message}"
  raise
end

module Integrity
  class Notifier
    class Notifo < Notifier::Base
      attr_reader :config

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/notifo.haml")
      end

      def initialize(build, config={})
        @account    = config.delete("account")
        @token      = config.delete("token")
        @recipients = config.delete("recipients")
        super(build, config)
      end

      def deliver!
        @notifo = ::Notifo.new(@account, @token)

        # multiple recipients can be comma separated
        @recipients.gsub(/\s/, '').split(',').each do |subscriber|
          @notifo.subscribe_user(subscriber)
          @notifo.post(subscriber, full_message, short_message, build_url)
        end if announce_build?
      end

      private
        def announce_build?
          build.failed? || config["announce_success"]
        end
      end

    register Notifo
  end
end
