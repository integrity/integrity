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

      def commit_url(commit, *path)
        project_url(commit.project, "commits", commit.identifier, *path)
      end

      def commit_path(commit, *path)
        project_path(commit.project, "commits", commit.identifier, *path)
      end

      def push_url_for(project)
        Addressable::URI.parse(project_url(project, "push")).tap do |url|
          if Integrity.config[:use_basic_auth]
            url.user     = Integrity.config[:admin_username]
            url.password = Integrity.config[:hash_admin_password] ?
              "<password>" : Integrity.config[:admin_password]
          end
        end.to_s
      end
    end
  end
end
