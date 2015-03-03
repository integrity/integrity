require 'app/helpers/authorization'
require 'app/helpers/breadcrumbs'
require 'app/helpers/date_time_helper'
require 'app/helpers/pretty_output'
require 'app/helpers/rendering'
require 'app/helpers/resources'
require 'app/helpers/urls'
require 'app/helpers/partials'
require 'app/helpers/authentication'

module Integrity
  module Helpers
    include Authorization
    include Authentication
    include Breadcrumbs
    include DateTimeHelper
    include PrettyOutput
    include Rendering
    include Resources
    include Urls

    include Sinatra::Partials
    include Rack::Utils

    alias :h :escape_html

    def settings_page?
      request.path_info.include?('settings')
    end

    def web_hook?
      request.path_info.include?('hook')
    end

    def status_update?
      request.path_info.include?('status.json')
    end

    def remote_ip
      request.env['HTTP_X_FORWARDED_FOR'].to_s
    end

    def setup_env
      set_base_url
      @load_utilization = LoadUtilization.current
      @usage = []
    end

    def set_base_url
      unless Integrity.base_url.present?
        Integrity.configure {|c| c.base_url = url_for('/', :full) }
      end
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

    def notify msg
      key, msg = msg.is_a?(Hash) ? msg.first : [:notice, msg]
      flash[key] = msg
    end

    private

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

    def log(msg)
      user = current_user ? "{user: #{current_user.username}}" : ""
      Integrity.logger.debug "[Integrity::App]: #{msg} user:#{user}"
    end

    def development?
      Integrity.development?
    end

    def production?
      Integrity.production?
    end

    def load_builds(project, limit=nil)
      project ||= current_project

      count = project.builds.count
      limit = limit || build_limit || count
      limit = count if limit == :all
      @showing_all_builds = count <= limit
      @builds = project.sorted_builds.all(limit: limit)

      @pending   = @builds.pending.all(order: :created_at.desc)
      @running   = @builds.running.all(order: :started_at.desc)
      @completed = @builds.completed.all(order: :completed_at.desc)

      limit = @showing_all_builds ? 12 : 4
      @latest_builds = @builds.all(limit: limit)
    end

    def load_branches(all=false)
      limit = all ? nil : 7
      @branches = current_project.branches.not_master.all(limit: limit)
      @branches += current_project.branches.master
    end

    def build_limit
      config.project_default_build_count
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
