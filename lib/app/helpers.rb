require 'app/helpers/authorization'
require 'app/helpers/breadcrumbs'
require 'app/helpers/date_time_helper'
require 'app/helpers/pretty_output'
require 'app/helpers/rendering'
require 'app/helpers/resources'
require 'app/helpers/urls'

module Integrity
  module Helpers
    include Authorization
    include Breadcrumbs
    include DateTimeHelper
    include PrettyOutput
    include Rendering
    include Resources
    include Urls

    include Rack::Utils

    alias :h :escape_html

    def show_login?
      Integrity.config.protected? && !authorized?
    end

    def project_metadata(project)
      label = project.human_status
      duration = project.human_duration
      time_elapsed = project.last_build.time_elapsed
      case project.status
        when :building then "Building for #{time_elapsed}"
        when :blank    then 'No builds found'
        when :pending  then label
        else "#{label} in #{duration}"
      end
    end

    private

    def build_all?
      config.build_all?
    end

    def github_token
      config.github_read_token
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
      @projects = authorized? ? Project.all : Project.all(public: true)

      # we may have no projects defined yet
      @status = :blank
      # statuses can be thought of as having the following hierarchy:
      # success -> pending -> building -> failed
      # status of Integrity overall is the rightmost status of
      # any of displayed projects.
      # statuses are listed in lib/integrity/build.rb.
      @projects.each do |project|

        # Project with no builds; Do not change overall status.
        next if project.blank?

        case @status
          when :blank
            # first project's status unconditionally sets overall status
            @status = project.status
          when :success
            # any status takes precedence over success
            @status = project.status unless project.successful?
          when :pending
            # building and failed take precedence over pending
            @status = project.status unless project.in?(:success, :pending)
          when :building
            # failed takes precedence over building
            @status = project.status if project.failed?
          else
            # overall status is failed, don't change it
            break
        end
      end
    end

  end
end
