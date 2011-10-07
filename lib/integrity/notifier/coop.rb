require 'net/http'
require 'json'

module Integrity
  class Notifier
    class Coop < Notifier::Base
      attr_reader :config

      def self.to_haml
        File.read(File.dirname(__FILE__) + "/coop.haml")
      end

      def deliver!
        coop_group = config["group"]
        coop_key = config["key"]

        headers = {
          "Accept"        => "application/json",
          "Content-Type"  => "application/json; charset=utf-8",
          "User-Agent"    => "Integrity Co-op Notifier"
        }

        connection = Net::HTTP.new("coopapp.com", 80)
        connection.post("/groups/#{coop_group}/notes", {:status => "#{full_message}", :key => "#{coop_key}"}.to_json, headers)
      end
      
      def full_message
        <<-EOM
Integrity: #{@build.project.name}: #{short_message} (#{build_url})
EOM
      end

      def to_s
        'Coop'
      end
    end

    register Coop
  end
end
