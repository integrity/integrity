module HonestyCluster
  EVENT_SOURCE = 'honesty-cluster'

  class Event < Sequel::Model
    set_dataset :events

    plugin :validation_helpers

    many_to_one :stack, key: :stack_id,   class: :"Pancakes::Stack"
    many_to_one :unit,  key: :service_id, class: :"Pancakes::Unit"

    #STATUS_REGEX = /\A(?<status_type>[A-Z_]+)_+(?<status_state>FAILED|IN_PROGRESS|COMPLETE)\z/

    def self.new_benchmarked_event(type:, status:, msg:nil, &block)
      return nil unless block_given?

      start = Time.now.utc
      block.call
      finish = Time.now.utc
      return new(
        source:    HonestyCluster::EVENT_SOURCE,
        timestamp: finish,
        type:      type,
        status:    status,
        message:   format(["took %.1fs", msg].flatten.join(': '), finish - start)
      )
      # dont worry about error handling for now
    #rescue RuntimeError => e
      #finish = Time.now.utc
      #return new(
        #source:    HonestyCluster::EVENT_SOURCE,
        #timestamp: finish,
        #type:      type,
        #status:    status + '_FAILED',
        #message:   format("failed after %.1fs: #{e.inspect}", finish - start)
      #)
    end

    def validate
      super
      validates_presence %i[source timestamp type status]
      #validates_format STATUS_REGEX, :status
    end

    def type
      [resource.class, super].join('::')
    end

    def resource
      unit || stack
    end

    def resource_name
      resource.resource_name
    end

    #def unit_owned?
      #!!unit
    #end

    #def stack_owned?
      #!!stack
    #end

    #def message_with_owner
      #["[#{owner_name}]", message].compact.join(' ')
    #end
  end
end
