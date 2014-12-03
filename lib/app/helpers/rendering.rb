module Integrity
  module Helpers
    module Rendering

      def stylesheets(*sheets)
        sheets.each do |sheet|
          haml_tag(:link, href: path("#{sheet}.css"), type: 'text/css', rel: 'stylesheet')
        end
      end

      def show(view, options={})
        @title = breadcrumbs(*options[:title])
        erb view, layout: true
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
        attrs = {name: name, type: 'checkbox', value: '1'}
        attrs[:checked] = !!condition
        attrs.update(extras)
        html = []
        attrs.each do |key, val|
          html << "#{key}=\"#{val}\""
        end
        html.join.html_safe
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
        Notifier.available.each_pair do |name, klass|
          notifiers << haml(klass.to_haml, layout: :notifier, locals: {
            notifier: name,
            enabled:  current_project.notifies?(name),
            config:   current_project.config_for(name) }).to_s
        end
        notifiers.join("\n").html_safe
      end

      def json(resource)
        headers 'Content-Type' => 'application/json; charset=utf-8'
        resource.to_json
      end

      def json_error(code, message)
        status code
        json({ 'error' => { 'code' => code, 'message' => message } })
      end
    end
  end
end
