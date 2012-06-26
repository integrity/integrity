module Integrity
  module Helpers
    module Resources
      def current_project
        @project ||= Project.first(:permalink => params[:project]) or
          raise Sinatra::NotFound
      end

      def current_build
        @build ||= current_project.builds.get(params[:build]) or
          raise Sinatra::NotFound
      end

      def update_notifiers_of(project)
        if params["notifiers"]
          project.update_notifiers(params["enabled_notifiers"] || [], params["notifiers"])
        end
      end
    end
  end
end
