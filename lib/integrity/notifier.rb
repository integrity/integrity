require File.dirname(__FILE__) + "/notifier/base"

module Integrity
  class Notifier
    include DataMapper::Resource

    property :id,      Integer,  :serial => true
    property :name,    String,   :nullable => false
    property :enabled, Boolean,  :nullable => false, :default  => false
    property :config,  Yaml,     :nullable => false, :lazy => false

    belongs_to :project, :class_name => "Integrity::Project"

    validates_is_unique :name, :scope => :project_id
    validates_present :project_id

    def self.register(klass)
      Integrity.register_notifier(klass)
    end

    def self.available
      Integrity.notifiers
    end

    def notify_of_build(build)
      to_const.notify_of_build(build, config)
    end

    private
      def to_const
        self.class.available[name]
      end
  end
end
