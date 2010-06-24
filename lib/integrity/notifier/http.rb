require 'net/http'

module Integrity
  class Notifier
    class HTTP < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "http_notifier_success" } Success
  %input.text#http_notifier_success{                          |
    :name => "notifiers[HTTP][success]",                      |
    :type => "text",                                     |
    :value => config["success"] ||                           |
      "http://0.0.0.0:3000" } |
%p.normal
  %label{ :for => "http_notifier_failure" } Failure
  %input.text#http_notifier_failure{                          |
    :name => "notifiers[HTTP][failure]",                      |
    :type => "text",                                     |
    :value => config["failure"] ||                           |
      "http://0.0.0.0:3000" } |

        HAML
      end

      def initialize(build, config={})
        @success = URI(config.delete("success"))
        @failure = URI(config.delete("failure"))
        super
      end

      def deliver!
        if short_message.include? "success"
          url = @success
        elsif short_message.include? "failed"
          url = @failure
        end
        begin
          Net::HTTP.post_form(url, {'name'=>build.project.name,'short_message'=>short_message,'author'=>build.commit.author.name,'commit_message'=>build.commit.message,'status'=>build.status,'url'=>build_url})
        rescue NameError
        end
      end
    end

    register HTTP
  end
end
