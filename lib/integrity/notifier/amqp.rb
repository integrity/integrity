require 'json'
require 'bunny'

module Integrity
  class Notifier
    class AMQP < Notifier::Base

      def initialize(build, config={})
        super
        @exchange_name = config['exchange_name']
        @queue_host    = config['queue_host']
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
