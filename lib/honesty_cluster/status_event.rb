module HonestyCluster
  class StatusEvent < Sequel::Model
    set_dataset :status_events
    plugin :timestamps
    plugin :validation_helpers

    many_to_one :stack, key: :stack_id,   class: :"Pancakes::Stack"
    many_to_one :unit,  key: :service_id, class: :"Pancakes::Unit"

    STATUS_REGEX = /\A(?<status_type>[A-Z_]+)_+(?<status_state>FAILED|IN_PROGRESS|COMPLETE)\z/

    def validate
      super
      validates_presence %i[source type status]
      validates_format STATUS_REGEX, :status
    end

    def complete?
      status_state == 'COMPLETE'
    end

    def in_progress?
      status_state == 'IN_PROGRESS'
    end

    def failed?
      status_state == 'FAILED'
    end

    #def owner
      #unit || stack
    #end

    #def unit_owned?
      #!!unit
    #end

    #def stack_owned?
      #!!stack
    #end

    #def owner_name
      #if unit_owned?
        #unit.service_name
      #elsif stack_owned?
        #stack.name
      #end
    #end

    #def msg(with_owner_name=false)
      #return nil unless message

      #if with_owner_name
        #"#{message} (#{owner_name})"
      #else
        #message
      #end
    #end

    private def status_parts
      @__status_parts ||= STATUS_REGEX.match(status)
    end

    private def status_type
      status_parts[:status_type]
    end

    private def status_state
      status_parts[:status_state]
    end
  end
end
