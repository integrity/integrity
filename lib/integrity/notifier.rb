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

    def self.available
      constants.map { |name| const_get(name) }.select { |notifier| valid_notifier?(notifier) }
    end

    def notify_of_build(build)
      to_const.notify_of_build(build, config)
    end

    private

      def to_const
        self.class.module_eval(name)
      end

      def self.valid_notifier?(notifier)
        notifier.respond_to?(:to_haml) && notifier.respond_to?(:notify_of_build) && notifier != Notifier::Base
      end
      private_class_method :valid_notifier?
  end
end
