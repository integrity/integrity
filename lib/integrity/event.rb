module Integrity
  class Event
    include Singleton

    attr_reader :registered_events

    class << self
      def on(*events, &block)
        instance.on(*events, &block)
      end

      def trigger(event, *args)
        instance.trigger(event, *args)
      end
    end

    def initialize
      @registered_events = {}

      #Why use this indirection for build.run? This is the only place builder.enqueue is called,
      #it could go straight in .run
      on('build:queue'){|build| Integrity.builder.enqueue(build) }

      on('build:start'){|build| Integrity.builder.run(:start_build, build) }

      on(*%w(
        build:cleanup
      )){|build| Integrity.builder.run(:destroy_build, build) }

      on('branch:cleanup'){|build| Build.get(build).cancel_previous_builds! }

      on(*%w(
        build:completed
        build:canceled
        machine:added
        build:queue:all
        app:start
      )){ Builder.queue_builds! }

      on('load:changed'){ Integrity.builder.check_load! }
    end

    def on(*events, &block)
      raise ArgumentError, 'Event required' unless events.first.present?
      events.each do |event|
        (@registered_events[event.to_sym] ||=[]) << block
      end
    end

    def trigger(event, *args)
      event = event.to_sym
      if (procs = @registered_events[event]).present?
        log_msg(event, *args)
        procs.each{|proc| proc.call(*args) }
      end
    end

    def log_msg(event, *args)
     arg_message = args.present? ? " with args #{args.join(',')}" : ''
     msg = "[Integrity::Event]: #{event} handled" + arg_message
     Integrity.logger.debug msg
    end
  end

end
