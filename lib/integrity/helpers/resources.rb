module Integrity
  module Helpers
    module Resources
      def current_project
        @project ||= Project.first(:permalink => params[:project]) or raise Sinatra::NotFound
      end

      def current_commit
        @commit ||= current_project.commits.first(:identifier => params[:commit]) or raise Sinatra::NotFound
      end
    end
  end
end