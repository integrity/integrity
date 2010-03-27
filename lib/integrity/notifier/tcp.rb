require "socket"

module Integrity
  class Notifier
    class TCP < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "tcp_notifier_uri" } Send to
  %input.text#tcp_notifier_uri{                          |
    :name => "notifiers[TCP][uri]",                      |
    :type => "text",                                     |
    :value => config["uri"] ||                           |
      "tcp://0.0.0.0:1234" } |
        HAML
      end

      def initialize(build, config={})
        @uri = URI(config.delete("uri"))
        super
      end

      def deliver!
        s = TCPSocket.open(@uri.host, @uri.port)
        s.puts("#{build.project.name}: #{short_message} | #{build_url}")
        s.close
      end
    end

    register TCP
  end
end
