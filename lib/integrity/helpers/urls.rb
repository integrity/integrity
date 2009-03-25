module Integrity
  module Helpers
    module Urls
      def root_url
        @url ||= Addressable::URI.parse(Integrity.config[:base_uri])
      end

      def root_path(path="")
        url(path).path
      end

      def project_url(project, *path)
        url("/" << [project.permalink, *path].flatten.join("/"))
      end

      def project_path(project, *path)
        project_url(project, path).path
      end

      def commit_url(commit)
        project_url(commit.project, "commits", commit.identifier)
      end

      def commit_path(commit, *path)
        commit_url(commit).path
      end

      def build_path(build, *path)
        warn "#build_path is deprecated, use #commit_path instead (#{caller[0]})"
        commit_path build.commit, *path
      end

      def build_url(build)
        warn "#build_url is deprecated, use #commit_url instead (#{caller[0]})"
        commit_url build.commit
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

      private
        def url(path="")
          root_url.dup.tap { |url| url.path = root_url.path + path }
        end
    end
  end
end
