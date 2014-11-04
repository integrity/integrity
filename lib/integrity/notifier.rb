module Integrity
  class Notifier
    include DataMapper::Resource

    property :id,      Serial
    property :name,    String,   :required => true
    property :enabled, Boolean,  :required => true, :default => false
    property :config,  Yaml,     :required => true, :lazy    => false

    belongs_to :project

    validates_uniqueness_of :name, :scope => :project

    def self.available
      @notifiers ||= {}
    end

    def self.register(class_name)
      available[class_name] = const_get(class_name)
    end

    def notify(build)
      klass && klass.notify(build, config)
    end

    def klass
      self.class.available[name]
    end

    def notify_of_build_start(build)
      klass.notify_of_build_start(build, config) if klass
    end

    autoload :AMQP, 'integrity/notifier/amqp'
    autoload :Campfire, 'integrity/notifier/campfire'
    autoload :Coop, 'integrity/notifier/coop'
    autoload :Email, 'integrity/notifier/email'
    autoload :Flowdock, 'integrity/notifier/flowdock'
    autoload :HTTP, 'integrity/notifier/http'
    autoload :IRC, 'integrity/notifier/irc'
    autoload :SES, 'integrity/notifier/ses'
    autoload :Shell, 'integrity/notifier/shell'
    autoload :TCP, 'integrity/notifier/tcp'
  end
end
