module Integrity
  module Helpers
    module Rendering

      def stylesheets(*sheets)
        sheets.each do |sheet|
          haml_tag(:link, href: path("#{sheet}.css"), type: 'text/css', rel: 'stylesheet')
        end
      end

      def show(view, options={})
        crumbs = options.delete(:title)
        @title = breadcrumbs(*crumbs)
        options = {layout: true}.merge(options)
        erb view, options
      end

      # def partial(template, locals={})
      #   haml("_#{template}".to_sym, locals: locals, layout: false)
      # end

      def errors_on(object, field)
        return '' unless errors = object.errors.on(field)
        errors.map {|e| e.gsub(/#{field} /i, '') }.join(', ')
      end

      def error_class(object, field)
        object.errors.on(field).nil? ? '' : 'with_errors'
      end

      def checkbox(name, condition, extras={})
        attrs = {name: name, type: 'checkbox', value: '1', checked: !!condition}.update(extras)
        attrs.map{|key, val| %Q{#{key}="#{val}"} }.join.html_safe
      end

      def dropdown(name, id, options, selected='')
        haml_tag(:select, id: id, name: name) do
          options.each {|opt|
            haml_tag :option, opt, value: opt, selected: (opt == selected)
          }
        end
      end

      def notifier_form
        notifiers = []
        Notifier.available.each do |name, klass|
          enabled = current_project.notifies?(name)
          config  = current_project.config_for(name)
          locals  = {notifier: name, name: name.downcase, enabled: enabled, config: config}
          notifiers << render_haml(klass, :notifier, locals)
        end
        notifiers.join("\n").html_safe
      end

      def json(resource)
        headers 'Content-Type' => 'application/json; charset=utf-8'
        resource.to_json rescue ''.to_json
      end

      def json_error(code, message)
        status code
        json({ 'error' => { 'code' => code, 'message' => message } })
      end

      def render_haml(klass, layout, locals={})
        haml(klass.to_haml, layout: layout, locals: locals).to_s
      end
    end
  end
end
