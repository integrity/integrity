module HonestyCluster
  class HonestyEvent < Sequel::Model
    set_dataset :honesty_events
    plugin :timestamps
    plugin :validation_helpers

    many_to_one :stack, key: :stack_id,   class: :"Pancakes::Stack"
    many_to_one :unit,  key: :service_id, class: :"Pancakes::Unit"

    #def owner
      #unit || stack
    #end

    def unit_owned?
      !!unit
    end

    def stack_owned?
      !!stack
    end

    def status_message
      msg = super
      return nil unless msg

      if unit_owned?
        "#{unit.service_name}: #{msg}"
      else
        msg
      end
    end

    def validate
      super
      validates_presence %i[source type status]
    end
  end
end
