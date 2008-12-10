module Integrity
  class Project
    include DataMapper::Resource

    property :id,         Integer,  :serial => true
    property :name,       String,   :nullable => false
    property :permalink,  String
    property :uri,        URI,      :nullable => false, :length => 255
    property :branch,     String,   :nullable => false, :default => "master"
    property :command,    String,   :nullable => false, :length => 255, :default => "rake"
    property :public,     Boolean,  :default => true
    property :building,   Boolean,  :default => false
    property :created_at, DateTime
    property :updated_at, DateTime

    has n, :builds, :class_name => "Integrity::Build"
    has n, :notifiers, :class_name => "Integrity::Notifier"

    before :save, :set_permalink
    before :destroy, :delete_code

    validates_is_unique :name

    def build(commit_identifier="HEAD")
      return if building?
      update_attributes(:building => true)
      ProjectBuilder.new(self).build(commit_identifier)
    ensure
      update_attributes(:building => false)
      send_notifications
    end

    def last_build
      builds.first(:order => [:created_at.desc])
    end

    def previous_builds
      builds.all(:order => [:created_at.desc]).tap { |builds| builds.shift }
    end

    def status
      last_build && last_build.status
    end

    def public=(flag)
      attribute_set(:public, !!flag)
    end
    
    def config_for(notifier)
      notifier = notifiers.first(:name => notifier.to_s.split(/::/).last)
      notifier.blank? ? {} : notifier.config
    end
    
    def notifies?(notifier)
      !notifiers.first(:name => notifier.to_s.split(/::/).last).blank?
    end
    
    def enable_notifiers(*args)
      Notifier.enable_notifiers(id, *args)
    end
    
    private
      def set_permalink
        self.permalink = (name || "").downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, "")
      end

      def delete_code
        builds.destroy!
        ProjectBuilder.new(self).delete_code
      end
      
      def send_notifications
        notifiers.each do |notifier|
          begin
            Integrity.log "Notifying of build #{last_build.short_commit_identifier} using the #{notifier.name} notifier"
            notifier.notify_of_build last_build
          rescue Timeout::Error
            Integrity.log "#{notifier.name} notifier timed out"
            next
          end
        end
      end
  end
end
