module Integrity
  module Helpers
    module Resources
      def current_project
        @project ||= Project.first(:permalink => params[:project]) or raise Sinatra::NotFound
      end

      def current_build
        @build ||= current_project.builds.first(:commit_identifier => params[:build]) or raise Sinatra::NotFound
      end
    end
  end
end