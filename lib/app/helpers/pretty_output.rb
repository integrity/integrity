module Integrity
  module Helpers
    module PrettyOutput

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
        status = case project.status
          when :success then {color: :green,  icon: :check,   circle: true}
          when :failed  then {color: :red,    icon: :times,   circle: true}
          when :pending then {color: :yellow, icon: :refresh, circle: false}
          else {color: :green,  icon: :check,   circle: true}
        end
        status[:icon] = "#{status[:icon]}-circle" if status[:circle]
        OpenStruct.new(status)
      end

      def branch_status(branch)
        status = case branch.status
                   when :success then {color: :green,  icon: :check,   circle: true}
                   when :failed  then {color: :red,    icon: :times,   circle: true}
                   when :pending then {color: :yellow, icon: :refresh, circle: false}
                   else {color: :green,  icon: :check,   circle: true}
                 end
        status[:icon] = "#{status[:icon]}-circle" if status[:circle]
        OpenStruct.new(status)
      end

      def status_time(project)
        if build = project.last_build
          time = case project.status
            when :success, :failed then build.completed_at
            when :pending, :building then build.started_at
          end
          time_ago_in_words(time)
        end
      end

      def link_to_logs(sha)
        "#{Integrity.logs_url}?q=#{sha}"
      end

    end
  end
end
