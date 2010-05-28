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
        string.gsub("\e[0m", '</span>').
          gsub("\e[31m", '<span class="color31">').
          gsub("\e[32m", '<span class="color32">').
          gsub("\e[33m", '<span class="color33">').
          gsub("\e[34m", '<span class="color34">').
          gsub("\e[35m", '<span class="color35">').
          gsub("\e[36m", '<span class="color36">').
          gsub("\e[37m", '<span class="color37">')
      end

      def pretty_date(date_time)
        days_away = (Date.today - Date.new(date_time.year, date_time.month, date_time.day)).to_i
        if days_away == 0
          "today"
        elsif days_away == 1
          "yesterday"
        elsif date_time == DateTime.new
          "unknown"
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
