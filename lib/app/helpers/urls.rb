require 'cgi'

module Integrity
  module Helpers
    module Urls
      def github_project_url(project, branch = nil)
        parts = project.uri.path.split('/').reject { |x| x.empty? }
        user  = parts.first
        repo  = parts.last.chomp('.git')

        if branch.nil? || project.branch == 'master'
          "http://github.com/#{user}/#{repo}"
        else
          "http://github.com/#{user}/#{repo}/compare/master...#{project.branch}"
        end
      end

      def github_project_link(project)
        url   = github_project_url(project)
        label = url['/compare/master'] ? 'Compare on GitHub' : 'Browse on GitHub'
        %Q{<a href="#{url}">#{label}</a>}
      end

      def github_commit_url(thing)
        if thing.is_a?(Integrity::Build)
          "#{github_project_url(thing.project)}/commit/#{thing.sha1}"
        elsif thing.is_a?(Integrity::Commit)
          "#{github_project_url(thing.project)}/commit/#{thing.identifier}"
        elsif thing.is_a?(Pancakes::Commit)
          "http://github.com/#{thing.repo}/commit/#{thing.sha}"
        end
      end

      def project_status_image_url(project)
        project_path(project).to_s.concat('.png')
      end

      def project_json_url(project, *path)
        project_url(project, *path).to_s.concat('.json')
      end

      def build_json_url(build, *path)
        build_url(build, *path).to_s.concat('.json')
      end

      def json_url_for(model, *path)
        url = case model
          when Integrity::Project
            project_url(project, *path)
          when Integrity::Build
            build_url(build, *path)
          end
        url.to_s.concat('.json')
      end

      def root_url
        root_uri(:full)
      end

      def root_path
        root_uri(:path_only)
      end

      def root_uri(type=:full)
        sfx = (type == :full) ? :url : :path
        var = :"@root_#{sfx}"
        uri = instance_variable_get(var)
        if uri.blank?
          uri = Addressable::URI.parse(url_for('/', type))
          instance_variable_set(var, uri)
        end
        uri
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
        path(project.try(:permalink), *path)
      end

      def branch_url(branch, *path)
        project_url(branch.project, branch.permalink, *path)
      end


      def branch_path(branch, *path)
        project_path(branch.project, branch.permalink, *path)
      end
      
      def build_url(build, *path)
        project_url(build.project, 'builds', build.id, *path)
      end

      def build_path(build, *path)
        project_path(build.project, 'builds', build.id, *path)
      end

      def artifact_path(build, artifact, *path)
        build_path(build, 'artifacts', CGI.escape(CGI.escape(artifact)))
      end

      def pancakes_path
        path('pancakes')
      end

      def pancakes_stack_path(stack)
        path('pancakes', 'stacks', stack.id)
      end

      def service_logs_url(unit)
        "#{Integrity.logs_url}?q=#{unit.name}"
      end

      def service_restart_url(service)
        "/pancakes/stacks/#{@stack.id}/services/#{service.id}/restart"
      end

      def service_check_health_url(service)
        "/pancakes/stacks/#{@stack.id}/services/#{service.id}/check_health"
      end


      # Copyright (MIT) Eric Kidd -- http://github.com/emk/sinatra-url-for
      #
      # Construct a link to +url_fragment+, which should be given relative to
      # the base of this Sinatra app.  The mode should be either
      # <code>:path_only</code>, which will generate an absolute path within
      # the current domain (the default), or <code>:full</code>, which will
      # include the site name and port number.  (The latter is typically
      # necessary for links in RSS feeds.)  Example usage:
      #
      #   url_for "/"            # Returns "/myapp/"
      #   url_for "/foo"         # Returns "/myapp/foo"
      #   url_for "/foo", :full  # Returns "http://example.com/myapp/foo"
      #--
      # See README.rdoc for a list of some of the people who helped me clean
      # up earlier versions of this code.
      def url_for url_fragment, mode=:path_only
        case mode
        when :path_only
          base = request.script_name
        when :full
          scheme = request.scheme
          if (scheme == 'http' && request.port == 80 ||
              scheme == 'https' && request.port == 443)
            port = ""
          else
            scheme = 'http'
            port = ":#{request.port}"
          end
          base = "#{scheme}://#{request.host}#{port}#{request.script_name}"
        else
          raise TypeError, "Unknown url_for mode #{mode}"
        end
        "#{base}#{url_fragment}"
      end
    end
  end
end
