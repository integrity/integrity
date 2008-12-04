module Integrity
  class Notifier
    include DataMapper::Resource
    
    property :id,      Integer,  :serial => true
    property :name,    String,   :nullable => false
    property :config,  Yaml,     :nullable => false, :lazy => false
    
    belongs_to :project, :class_name => "Integrity::Project"
    
    validates_is_unique :name, :scope => :project_id
    validates_present :project_id
    
    def self.available
      @available ||= constants.map {|name| const_get(name) }.select do |notifier|
        notifier.respond_to?(:to_haml) && notifier.respond_to?(:notify_of_build)
      end - [Notifier::Base]
    end
    
    def self.enable_notifiers(project, enabled, config={})
      all(:project_id => project).destroy!
      list_of_enabled_notifiers(enabled).each do |name|
        create! :project_id => project, :name => name, :config => config[name]
      end
    end
    
    def notify_of_build(build)
      to_const.notify_of_build(build, config)
    end
    
    private
      
      def to_const
        self.class.module_eval(name)
      end
      
      def self.list_of_enabled_notifiers(names)
        case names
          when Array then names
          when NilClass then []
          else [names]
        end
      end
  end
end

require File.dirname(__FILE__) / 'notifier' / 'base'

Dir["#{File.dirname(__FILE__)}/notifier/*.rb"].each &method(:require)
