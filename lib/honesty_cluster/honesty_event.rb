module HonestyCluster
  class HonestyEvent < Sequel::Model
    set_dataset :honesty_events
    plugin :timestamps
    plugin :validation_helpers

    many_to_one :stack, key: :stack_id,   class: :"Pancakes::Stack"
    many_to_one :unit,  key: :service_id, class: :"Pancakes::Unit"

    def validate
      super
      #validates_exact_length 40, :sha
      validates_presence %i[source type status]
    end

    def complete?
      status.end_with?('_COMPLETE')
    end

    def in_progress?
      status.end_with?('_IN_PROGRESS')
    end

    def failed?
      status.end_with?('_FAILED')
    end

    def unknown?
      !(complete? || in_progress? || failed?)
    end
  end
end
