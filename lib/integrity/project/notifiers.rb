module Integrity
  class Project
    module Helpers
      module Notifiers
        def notifies?(notifier)
          !! notifiers.first(:name => notifier)
        end

        def enabled_notifiers
          notifiers.all(:enabled => true)
        end

        def config_for(notifier)
          notifier = notifiers.first(:name => notifier)
          notifier ? notifier.config : {}
        end

        def update_notifiers(to_enable, config)
          disable_notifiers(to_enable)

          config.each_pair { |name, config|
            notifier = notifiers.first(:name => name)
            notifier ||= notifiers.new(:name => name)

            notifier.enabled = true
            notifier.config  = config
            notifier.save
          }
        end

        private
          def disable_notifiers(to_enable)
            enabled_notifiers.select { |notifier|
              ! to_enable.include?(notifier.name) }.
                each { |notifier|
                  notifier.update_attributes(:enabled => false) }
          end
      end
    end
  end
end
