require 'dm-validations'
require 'dm-types'

module Integrity
  class Build
    include DataMapper::Resource

    property :id,       Integer,  :serial => true
    property :output,   Text,     :nullable => false, :default => ''
    property :error,    Text,     :nullable => true,  :default => ''
    property :commit,   Yaml,     :nullable => false
    property :status,   Boolean,  :nullable => false, :default => false

    def success?
      status
    end

    def failure?
      !success?
    end

    def human_readable_status
      success? ? 'Successful' : 'Fail'
    end
  end
end
