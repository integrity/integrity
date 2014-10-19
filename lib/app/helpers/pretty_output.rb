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

      def date_in_pst(time)
        as_date(in_pst(time))
      end

      def as_date(time)
        Date.new(time.year, time.month, time.day)
      end

      def in_pst(time)
        time.to_time.in_time_zone('Pacific Time (US & Canada)')
      end
    end
  end
end
