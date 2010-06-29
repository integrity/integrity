require 'json'
require 'bunny'

module Integrity
  class Notifier
    class AMQP < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "amqp_queue_host" } Host
  %input.text#amqp_queue_host{                |
    :name => "notifiers[AMQP][queue_host]",   |
    :type => "text",                          |
    :value => config["queue_host"] ||         |
      "localhost" }                           |
%p.normal
  %label{ :for => "amqp_queue_name" } Queue
  %input.text#amqp_queue_name{                |
    :name => "notifiers[AMQP][queue_name]",   |
    :type => "text",                          |
    :value => config["queue_name"] ||         |
      "integrity" }                           |
        HAML
      end

      def initialize(build, config={})
        @queue_name = config.delete("queue_name")
        @queue_host = config.delete("queue_host")
        super
      end

      def deliver!
        b = Bunny.new(:host => @queue_host)

        # start a communication session with the amqp server
        b.start

        # declare a queue
        q = b.queue(@queue_name)

        # json message to be put on the queue
        msg = JSON.generate({
          "name"    => build.project.name,
          "status"  => build.status,
          "url"     => build_url,
          "author"  => build.commit.author.name,
          "message" => build.commit.message
        })

        # publish a message to the queue
        q.publish(msg)

        # close the connection
        b.stop
      end
    end

    register AMQP
  end
end
