module Integrity
  module Helpers
    module Rendering
      def stylesheets(*sheets)
        sheets.each { |sheet|
          haml_tag(:link, :href => path("#{sheet}.css"),
            :type => "text/css", :rel => "stylesheet")
        }
      end

      def show(view, options={})
        @title = breadcrumbs(*options[:title])
        haml view
      end

      def partial(template, locals={})
        haml("_#{template}".to_sym, :locals => locals, :layout => false)
      end

      def errors_on(object, field)
        return "" unless errors = object.errors.on(field)
        errors.map {|e| e.gsub(/#{field} /i, "") }.join(", ")
      end

      def error_class(object, field)
        object.errors.on(field).nil? ? "" : "with_errors"
      end

      def checkbox(name, condition, extras={})
        attrs = {:name => name, :type => "checkbox", :value => "1"}
        attrs[:checked] = !!condition
        attrs.update(extras)
      end

      def dropdown(name, id, options, selected="")
        haml_tag(:select, :id => id, :name => name) {
          options.each { |opt|
            haml_tag :option, opt, :value => opt, :selected => (opt == selected)
          }
        }
      end

      def notifier_form
        Notifier.available.each_pair { |name, klass|
          haml_concat haml(klass.to_haml, :layout => :notifier, :locals => {
            :notifier => name,
            :enabled  => current_project.notifies?(name),
            :config   => current_project.config_for(name) })
        }
      end
      
      def build_artifacts(build)
        artifacts = {}
        build.project.get_artifacts.each do |artifact|
          if File.exists?("#{Integrity.config.directory}/#{build.id}/#{artifact}") && ! artifact.include?("*")
            if artifact.include?("/")
              artifact_url = artifact.gsub(/(\/)/, "%2F")
            else
              artifact_url = artifact
            end
            artifacts.update(
              { artifact => artifact_url }
            )
          elsif (File.exists?("#{Integrity.config.directory}/#{build.id}/#{artifact}") && artifact.include?("*")) || artifact.include?("*")
            Dir["#{Integrity.config.directory}/#{build.id}/#{artifact}"].each do |wildcarded|
              wildcarded = wildcarded.split("#{Integrity.config.directory}/#{build.id}/")[1]
              if wildcarded.include?("/")
                wildcard_url = wildcarded.gsub(/(\/)/, "%2F")
              else
                wildcard_url = wildcarded
              end
              artifacts.update(
                { wildcarded => wildcard_url }
              )
            end
          end
        end
        artifacts
      end
    end
  end
end
