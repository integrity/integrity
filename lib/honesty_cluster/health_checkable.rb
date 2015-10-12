module HonestyCluster

  ## check for the status of one particular thing
  #class DeprecatedStatusCheck
    #attr_reader :status, :message

    ## all possible statuses ordered by importance
    ## ie, if a status is failed, then we dont care about statuses after failed in this list
    #PRIORITIZED_STATUSES = [
      #:failed,
      #:in_progress,
      #:complete,
    #]

    #def initialize(status, message=nil)
      #raise("invalid status '#{status}'") unless PRIORITIZED_STATUSES.include?(status)
      #@status = status
      #@message = message
    #end

    #def okay?
      #status == :complete
    #end
  #end

  ## represent the overall health of some resource by aggregating it's StatusChecks
  #class DeprecatedHealthCheck
    #attr_reader :status_checks, :owner_name

    #def initialize(status_checks, owner_name=nil)
      #@status_checks = status_checks
      #@owner_name = owner_name
    #end

    ## bake this aggregation into a single thing
    #def to_status
      #StatusCheck.new(status, message)
    #end

    #def status
      #prioritized_status_checks[:status]
    #end

    #def message
      #msg = prioritized_status_checks[:checks].map(&:message).join('; ')
      #if owner_name
        #"#{msg} (#{owner_name})"
      #else
        #msg
      #end
    #end

    #def healthy?
      #status == :complete
    #end

    #private def grouped_status_checks
      #@__groups ||= status_checks.group_by do |check|
        #check.status
      #end
    #end

    ## return the status checks with the most important status
    #private def prioritized_status_checks
      #StatusCheck::PRIORITIZED_STATUSES.map do |status|
        #[
          #status,
          #grouped_status_checks[status] || [],
        #]
      #end
      #.each do |status,group|
        #if !group.empty?
          #return { status: status, checks: group }
        #end
      #end
      #raise('expected some status checks')
    #end
  #end

  class HealthCheck
    attr_reader :healthy, :timestamp, :message

    STATUS_HEALTHY   = 'HEALTHY'
    STATUS_UNHEALTHY = 'UNHEALTHY'

    def initialize(healthy, message=nil, timestamp=Time.now.utc)
      @healthy = healthy
      @timestamp = timestamp
      @message = message
    end

    def self.new_from_event(event)
      new(
        event.status == STATUS_HEALTHY,
        event.message,
        event.timestamp,
      )
    end

    def to_s
      [health_str, message].join(': ')
    end

    def health_str
      healthy ? STATUS_HEALTHY : STATUS_UNHEALTHY
    end

    alias :"healthy?" :healthy
  end

  module HealthCheckable
    extend ActiveSupport::Concern

    #included do
    #end

    # @api private
    private def create_event_for_health_check(health_check)
      add_event(
        source:    'honesty',
        timestamp: health_check.timestamp,
        type:      health_check_event_type,
        status:    health_check.health_str,
        message:   health_check.message,
      )
    end

    # @api private
    private def health_check_event_type
      "HealthCheck"
    end

    #def initial_health_check!
      #create_event_for_health_check(HealthCheck.new(false, 'resource created'))
    #end

    def last_health_check_event
      events_dataset.where(type: health_check_event_type).reverse_order(:timestamp).limit(1).first
    end

    def last_health_check
      last_hc = last_health_check_event
      last_hc ? HealthCheck.new_from_event(last_hc) : nil
    end

    #def healthy?
      #last_hc = last_health_check
      #last_hc && last_health_check.healthy?
    #end

    def check_health!
      curr = current_health
      if !curr || !curr.is_a?(HealthCheck)
        raise HonestyCluster::Error, "#check_health! returned #{curr.inspect}"
      else
        event = create_event_for_health_check(curr)
        HealthCheck.new_from_event(event)
      end
    end

    def current_health
      raise('must implement and return an instance of HealthCheck')
    end

    #module ClassMethods
      #attr_reader :_health_check_type

      #def health_check_type(type)
        #raise("invalid health_check_type '#{type}'") unless type && !type.empty?
        #@_health_check_type = "#{type}::HealthCheck"
      #end
    #end
  end
end
