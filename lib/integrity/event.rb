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

      on(*%w(
        build:completed
        build:canceled
        machine:added
      )){ Builder.queue_builds! }

      on('build:cleanup'){|build_id| Builder.destroy_build(Build.get(build_id)) }
      on('diligence_branch:deactivate'){|build_id| DiligenceBranch.deactivate(build_id)}
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
        procs.each{|proc| proc.call(*args) }
      end
    end
  end
end