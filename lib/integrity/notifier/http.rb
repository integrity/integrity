require 'net/http'

module Integrity
  class Notifier
    class HTTP < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "http_notifier_url" } URL
  %input.text#http_notifier_url{            |
    :name => "notifiers[HTTP][url]",        |
    :type => "text",                        |
    :value => config["url"] ||              |
      "http://0.0.0.0:3000" }               |
        HAML
      end

      def initialize(build, config={})
        @url = URI(config.delete("url"))
        super
      end

      def deliver!
        Net::HTTP.post_form(@url, {
          "name"           => build.project.name,
          "short_message"  => short_message,
          "author"         => build.commit.author.name,
          "commit_message" => build.commit.message,
          "status"         => build.status,
          "url"            => build_url
        })
      end
    end

    register HTTP
  end
end
