require 'uri'
require 'net/http'
require 'net/https'

module Integrity
  class Notifier
    class Flowdock < Notifier::Base
      attr_reader :config

      def self.to_haml
        @haml ||= File.read(File.dirname(__FILE__) + "/flowdock.haml")
      end

      def deliver!
        token = config["token"]

        headers = {
          "Accept"        => "application/json",
          "Content-Type"  => "application/json; charset=utf-8",
          "User-Agent"    => "Integrity Flowdock Notifier",
        }

        uri = URI.parse("https://api.flowdock.com/v1/messages/team_inbox/#{token}")

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        post = Net::HTTP::Post.new(uri.path, headers)
        post.body = {
          "source"        => "Integrity",
          "subject"       => short_message,
          "content"       => "<pre>#{full_message}</pre>",
          "from_address"  => config["from_address"],
          "link"          => build_url,
          "tags"          => ["integrity", build.failed? ? "failure" : "success"]
        }.to_json

        response = https.request(post)
      end

      def announce_build?
        build.failed? || config["announce_success"]
      end
    end

    register Flowdock
  end
end
