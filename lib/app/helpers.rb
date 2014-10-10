require "app/helpers/authorization"
require "app/helpers/breadcrumbs"
require "app/helpers/pretty_output"
require "app/helpers/rendering"
require "app/helpers/resources"
require "app/helpers/urls"

module Integrity
  module Helpers
    include Authorization, Breadcrumbs, PrettyOutput,
      Rendering, Resources, Urls

    include Rack::Utils
    alias :h :escape_html

    def show_login?
      Integrity.config.protected? && !authorized?
    end

    private

    def build_all?
      config.build_all?
    end

    def github_token
      config.github_token
    end

    def github_enabled?
      config.github_enabled?
    end

    def github_secret
      config.github_secret
    end

    def config
      Integrity.config
    end

    def load_projects
      @projects = authorized? ? Project.all : Project.all(:public => true)

      # we may have no projects defined yet
      @status = :blank
      # statuses can be thought of as having the following hierarchy:
      # success -> pending -> building -> failed
      # status of Integrity overall is the rightmost status of
      # any of displayed projects.
      # statuses are listed in lib/integrity/build.rb.
      @projects.each do |project|
        if project.status == :blank
          # project with no builds.
          # do not change overall status
          next
        end

        case @status
          when :blank
            # first project's status unconditionally sets overall status
            @status = project.status
          when :success
            # any status takes precedence over success
            if project.status != :success
              @status = project.status
            end
          when :pending
            # building and failed take precedence over pending
            if project.status != :success && project.status != :pending
              @status = project.status
            end
          when :building
            # failed takes precedence over building
            if project.status == :failed
              @status = :failed
            end
          else
            # overall status is failed, don't change it
            break
        end
      end
    end

  end
end
