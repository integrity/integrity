module Integrity
  module Helpers
    module Breadcrumbs
      def pages
        @pages ||= [["projects", root_path], ["new project", path("/new")]]
      end

      def breadcrumbs(*crumbs)
        crumbs[0..-2].map do |crumb|
          if page_data = pages.detect {|c| c.first == crumb }
            %Q(<a href="#{page_data.last}">#{page_data.first}</a>)
          elsif @project && @project.permalink == crumb
            %Q(<a href="#{project_path(@project)}">#{@project.permalink}</a>)
          end
        end + [crumbs.last]
      end
    end
  end
end
