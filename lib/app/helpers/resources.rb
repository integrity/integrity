module Integrity
  module Helpers
    module Resources
      def current_project
        @project ||= Project.first(permalink: params[:project]) or raise Sinatra::NotFound
      end

      def current_branch
        @branch ||= current_project.branches.first(permalink: params[:branch]) or raise Sinatra::NotFound
      end

      def current_build
        @build ||= current_project.builds.get!(params[:build])
      end

      def all_builds(limit=5)
        Integrity::Build.all(order: :created_at.desc, limit: limit)
      end

      def all_developers
        Tracker::User.all(developer: true)
      end

      def all_product_managers
        Tracker::User.all(product: true)
      end

      def lineup_roles
        ['sheriff', 'deputy', 'ranger', 'santa']
      end

      def update_notifiers_of(project)
        if notifiers = params[:notifiers]
          enabled = params[:enabled_notifiers] || []
          project.update_notifiers(enabled, notifiers)
        end
      end

      def artifact_files(build)
        files = build.artifact_files
        files = files.map do |file|
          file = file.dup
          url = artifact_path(build, file[:relative_path])
          file[:url] = url
          file
        end
        files
      end
    end
  end
end
