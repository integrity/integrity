module Integrity
  module Helpers
    module Urls
      def root_url
        @root_url ||= Addressable::URI.parse(url_for("/", :full))
      end

      def root_path
        @root_path ||= Addressable::URI.parse(url_for("/", :path_only))
      end

      def url(*path)
        root_url.join(path.join("/"))
      end

      def path(*path)
        root_path.join(path.join("/"))
      end

      def project_url(project, *path)
        url(project.permalink, *path)
      end

      def project_path(project, *path)
        path(project.permalink, *path)
      end

      def build_url(build, *path)
        project_url(build.project, "builds", build.id, *path)
      end

      def build_path(build, *path)
        project_path(build.project, "builds", build.id, *path)
      end
    end
  end
end
