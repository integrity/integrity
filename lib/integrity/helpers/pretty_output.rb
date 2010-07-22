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

      def pretty_date(date_time)
        unless date_time
          return "commit date not loaded"
        end

        days_away = (Date.today - Date.new(date_time.year, date_time.month, date_time.day)).to_i
        if days_away == 0
          "today"
        elsif days_away == 1
          "yesterday"
        else
          strftime_with_ordinal(date_time, "on %b %o")
        end
      end

      def strftime_with_ordinal(date_time, format_string)
        ordinal = case date_time.day
          when 1, 21, 31 then "st"
          when 2, 22     then "nd"
          when 3, 23     then "rd"
          else                "th"
        end

        date_time.strftime(format_string.gsub("%o", date_time.day.to_s + ordinal))
      end
    end
  end
end
