require 'net/https'
require 'uri'
require 'openssl'

module Integrity
  class Notifier
    class Notifo < Notifier::Base
      attr_reader :config

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/notifo.haml")
      end

      def initialize(build, config={})
        @subscribe_url = URI.parse('https://api.notifo.com/v1/subscribe_user')
        @notification_url = URI.parse('https://api.notifo.com/v1/send_notification')
        @account = config.delete("account")
        @token= config.delete("token")
        @recipients= config.delete("recipients")
        super
      end

      def deliver!
        @title = "#{build.project.name} build #{build.successful? ? 'successful' : 'failed'}"
        @msg = "#{build.commit.author.name}: #{build.commit.message}"
        @url = build_url
        # multiple recipients can be comma separated
        @recipients.gsub(/\s/, '').split(',').each do |subscriber|
          subscribe_user(subscriber)
          send_notification(subscriber, @msg, @title, @url)
        end
      end

      private
        def announce_build?
          build.failed? || config["announce_success"]
        end

        def subscribe_user(username)
          req = Net::HTTP::Post.new(@subscribe_url.path)
          req.basic_auth(@account, @token)
          req.set_form_data('username' => username)
          net = Net::HTTP.new(@subscribe_url.host, 443)
          net.use_ssl = true
          net.verify_mode = OpenSSL::SSL::VERIFY_NONE
          net.start {|http| http.request(req)}
        end

        def send_notification(user, msg, title, callback)
          req = Net::HTTP::Post.new(@notification_url.path)
          req.basic_auth(@account, @token)
          req.set_form_data( 'to' => URI.escape(user, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
                             'msg' => URI.escape(msg, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
                             'title' => URI.escape(title, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
                             'uri' => URI.escape(callback, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
          )
          net = Net::HTTP.new(@notification_url.host, 443)
          net.use_ssl = true
          net.verify_mode = OpenSSL::SSL::VERIFY_NONE
          net.start {|http| http.request(req)}

        end
      end

    register Notifo
  end
end
