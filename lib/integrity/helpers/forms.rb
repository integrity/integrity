module Integrity
  module Helpers
    module Forms
      def errors_on(object, field)
        return "" unless errors = object.errors.on(field)
        errors.map {|e| e.gsub(/#{field} /i, "") }.join(", ")
      end

      def error_class(object, field)
        object.errors.on(field).nil? ? "" : "with_errors"
      end

      def checkbox(name, condition, extras={})
        attrs = { :name => name, :type => "checkbox", :value => "1" }
        attrs.merge!(:checked => condition ? true : nil)
        attrs.merge(extras)
      end

      def notifier_form(notifier)
        haml(notifier.to_haml, :layout => :notifier, :locals => {
          :config => current_project.config_for(notifier),
          :notifier => "#{notifier.to_s.split(/::/).last}",
          :enabled => current_project.notifies?(notifier)
        })
      end
    end
  end
end