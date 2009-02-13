module Integrity
  module Helpers
    module Rendering
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
