module Integrity
  class Project
    module Notifiers
      def enabled_notifiers
        notifiers.all(:enabled => true)
      end

      def notifies?(notifier)
        notifiers.first(:name => notifier, :enabled => true)
      end

      def config_for(notifier)
        notifier = notifiers.first(:name => notifier)
        notifier ? notifier.config : {}
      end

      def update_notifiers(to_enable, config)
        config.each_pair { |name, config|
          notifier = notifiers.first_or_create(:name => name)
          notifier.enabled = to_enable.include?(name)
          notifier.config  = config
          notifier.save
        }
      end
    end
  end
end
