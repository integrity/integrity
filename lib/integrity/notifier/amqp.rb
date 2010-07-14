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
  %label{ :for => "amqp_exchange_name" } Exchange
  %input.text#amqp_exchange_name{                 |
    :name => "notifiers[AMQP][exchange_name]",    |
    :type => "text",                              |
    :value => config["exchange_name"] ||          |
      "integrity" }                               |
        HAML
      end

      def initialize(build, config={})
        @exchange_name = config.delete("exchange_name")
        @queue_host = config.delete("queue_host")
        super
      end

      def deliver!
        b = Bunny.new(:host => @queue_host)

        # start a communication session with the amqp server
        b.start

        # declare exchange
        exch = b.exchange(@exchange_name, :type => :fanout)

        # json message to be put on the queue
        msg = JSON.generate({
          "name"    => build.project.name,
          "status"  => build.status,
          "url"     => build_url,
          "author"  => build.commit.author.name,
          "message" => build.commit.message
        })

        # publish a message to the queue
        exch.publish(msg)

        # close the connection
        b.stop
      end
    end

    register AMQP
  end
end
