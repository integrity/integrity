module Integrity
  class Event
    include Singleton

    def initialize
      @registered_events = {}
      add_event_listener('queue_builds') do
        Integrity::Builder.queue_builds!
      end
      add_event_listener('destroy_build') do |build_id|
        Builder.destroy_build(Integrity::Build.get(build_id))
      end
    end

    def add_event_listener(event, &block)
      (@registered_events[event] ||=[]) << block
    end

    def dispatch_event(event, *args)
      if @registered_events[event]
        @registered_events[event].each do |proc_block|
          proc_block.call(*args)
        end
      end
    end
  end
end