module Integrity
  module Helpers
    module Urls
      def url(path)
        url = "#{request.scheme}://#{request.host}"

        if request.scheme == "https" && request.port != 443 ||
            request.scheme == "http" && request.port != 80
          url << ":#{request.port}"
        end

        url << "/" unless path.index("/").zero?
        url << path
      end

      def root_url
        url("/")
      end

      def project_path(project, *path)
        "/" << [project.permalink, *path].join("/")
      end

      def project_url(project, *path)
        url project_path(project, *path)
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

      def commit_path(commit, *path)
        project_path(commit.project, "commits", commit.identifier, *path)
      end
      
      def build_path(build, *path)
        warn "#build_path is deprecated, use #commit_path instead"
        commit_path build.commit, *path
      end

      def commit_url(commit)
        url commit_path(commit)
      end

      def build_url(build)
        warn "#build_url is deprecated, use #commit_url instead"
        commit_url build.commit
      end
    end
  end
end