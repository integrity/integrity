module Integrity
  module Helpers
    module Rendering
      def stylesheets(*sheets)
        sheets.each { |sheet|
          haml_tag(:link, :href => root_path("/#{sheet}.css"),
            :type => "text/css", :rel => "stylesheet")
        }
      end

      def stylesheet_hash
        @_hash ||= Digest::MD5.file(options.views + "/integrity.sass").hexdigest
      end

      def show(view, options={})
        @title = breadcrumbs(*options[:title])
        haml view
      end

      def partial(template, locals={})
        haml("_#{template}".to_sym, :locals => locals, :layout => false)
      end
    end
  end
end
