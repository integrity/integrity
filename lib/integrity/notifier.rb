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
      constants.map {|name| const_get(name) }.select do |notifier|
        notifier.respond_to?(:to_haml) && notifier.respond_to?(:notify_of_build)
      end
    end
    
    def setup(list, config)
      all.destroy!
      
      list = case list
        when Array then list
        when NilClass then []
        else [list]
      end
      
      list.each do |name|
        create! :name => name, :config => config[name]
      end
    end
    
    def notify_of_build(build)
      to_const.notify_of_build(build, config)
    end
    
    private
      
      def to_const
        self.class.module_eval(name)
      end
  end
end

Dir["#{File.dirname(__FILE__)}/notifier/*.rb"].each &method(:require)
