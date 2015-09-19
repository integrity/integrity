module Integrity
  module Helpers
    module PrettyOutput
       TRACKER_URL = 'https://www.pivotaltracker.com/n/projects/422567/stories/'

      def t(*args)
        I18n.t(*args)
      end

      def l(object, options=nil)
        I18n.l(object, options)
      end

      def cycle(*values)
        @cycles ||= {}
        @cycles[values] ||= -1 # first value returned is 0
        next_value = @cycles[values] = (@cycles[values] + 1) % values.size
        values[next_value]
      end

      def bash_color_codes(string)
        Bcat::ANSI.new(string).to_html
      end

      def pretty_date(date)
        return 'commit date not loaded'unless date
        today = date_in_pst(Date.today)
        date  = date_in_pst(date)
        days  = (today - date).to_i
        case days
          when 0 then 'today'
          when 1 then 'yesterday'
          else strftime_with_ordinal(date, 'on %b %o')
        end
      end

      def strftime_with_ordinal(date_time, format_string)
        ordinal = case date_time.day
          when 1, 21, 31 then 'st'
          when 2, 22     then 'nd'
          when 3, 23     then 'rd'
          else                'th'
        end
        date_time.strftime(format_string.gsub('%o', date_time.day.to_s + ordinal))
      end

      def project_status(project)
        status = project ? get_status(project.status) : get_status(nil)
        status.icon = "#{status.icon}-o" if status.icon == :clock
        status.icon = "#{status.icon}-circle" if status.circle
        status
      end
      alias_method :branch_status, :project_status
      alias_method :build_status, :project_status

      def status_time(model)
        build = model.is_a?(Integrity::Build) ? model : model.last_build
        if build.present?
          time = case build.status
            when :success, :failed then build.completed_at
            when :pending, :building then build.started_at
          end
          time_ago_in_words(time)
        end
      end

      def get_status(status)
        Hashie::Mash.new(
          case status
            when :success   then {color: :green,  icon: :check,    circle: true}
            when :failed    then {color: :red,    icon: :times,    circle: true}
            when :pending   then {color: :yellow, icon: :clock,    circle: false}
            when :building  then {color: :blue,   icon: 'refresh fa-spin',  circle: false}
            when :killed    then {color: :grey,   icon: :ban,      circle: false}
            when :cancelled then {color: :grey,   icon: :ban,      circle: false}
            else                 {color: :grey,   icon: :question, circle: true}
          end
        )
      end

      #def build_service(build)
        #case build.service_template
        #when 'spec' then {color: :warning, icon: :bug}
        #when 'spec_psql' then {color: :warning, icon: :bug}
        #when 'server' then {color: :info, icon: :laptop}
        #end
      #end

      def message(build)
        msg = build.try(:full_message).to_s
        msg.length > 100 ? "#{msg[0..96]}..." : msg
      end

      def link_to_logs(build)
        "#{Integrity.logs_url}?q=#{logs_query(build)}"
      end

      def logs_query(build)
        if build.completed?
          "#{build.service_name} AND ([Honesty] OR examples,)"
        else
          "#{build.service_name}"
        end
      end

      def link_to_tracker(build)
        tracker_id = build.branch.try(:name).scan(/\d{6,}/).last
        TRACKER_URL + tracker_id if tracker_id
      end

      def pacific_time(time)
        return if !time
        time.in_time_zone("Pacific Time (US & Canada)")
      end

      def pretty_time(time)
        return if !time
        pacific_time(time).try(:strftime, '%m/%d %R')
      end

      def pancakes_state_bootstrap_class(pancakes)
        if pancakes.running?
          'success'
        elsif pancakes.starting?
          'info'
        elsif pancakes.failed?
          'danger'
        elsif pancakes.off?
          'default'
        elsif pancakes.fucked_up?
          'default'
        else
          'default'
        end
      end
    end
  end
end
