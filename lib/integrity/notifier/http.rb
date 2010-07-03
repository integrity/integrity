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
        Net::HTTP.post_form(@url,
          {"name"    => build.project.name,
           "status"  => build.status,
           "url"     => build_url,
           "repo"    => build.project.uri,
           "branch"  => build.project.branch,
           "commit"  => build.commit.identifier,
           "author"  => build.commit.author.name,
           "message" => build.commit.message}
        )
      end
    end

    register HTTP
  end
end
