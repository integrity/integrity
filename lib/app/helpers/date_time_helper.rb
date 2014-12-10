module Integrity
  module Helpers
    module DateTimeHelper

      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false, options = {})
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time   = to_time.to_time if to_time.respond_to?(:to_time)

        distance_in_minutes = (((to_time - from_time).abs)/60).round
        distance_in_seconds = ((to_time - from_time).abs).round

        I18n.with_options locale: options[:locale], scope: :'datetime.distance_in_words' do |locale|
          case distance_in_minutes
            when 0..1
              return distance_in_minutes == 0 ?
                locale.t(:less_than_x_minutes, count: 1) :
                locale.t(:x_minutes, count: distance_in_minutes) unless include_seconds

              case distance_in_seconds
                when 0..4   then locale.t :less_than_x_seconds, count: 5
                when 5..9   then locale.t :less_than_x_seconds, count: 10
                when 10..19 then locale.t :less_than_x_seconds, count: 20
                when 20..39 then locale.t :half_a_minute
                when 40..59 then locale.t :less_than_x_minutes, count: 1
                else             locale.t :x_minutes,           count: 1
              end

            when 2..44           then locale.t :x_minutes,      count: distance_in_minutes
            when 45..89          then locale.t :about_x_hours,  count: 1
            when 90..1439        then locale.t :about_x_hours,  count: (distance_in_minutes.to_f / 60.0).round
            when 1440..2519      then locale.t :x_days,         count: 1
            when 2520..43199     then locale.t :x_days,         count: (distance_in_minutes.to_f / 1440.0).round
            when 43200..86399    then locale.t :about_x_months, count: 1
            when 86400..525599   then locale.t :x_months,       count: (distance_in_minutes.to_f / 43200.0).round
            else
              fyear = from_time.year
              fyear += 1 if from_time.month >= 3
              tyear = to_time.year
              tyear -= 1 if to_time.month < 3
              leap_years = (fyear > tyear) ? 0 : (fyear..tyear).count{|x| Date.leap?(x)}
              minute_offset_for_leap_year = leap_years * 1440
              # Discount the leap year days when calculating year distance.
              # e.g. if there are 20 leap year days between 2 dates having the same day
              # and month then the based on 365 days calculation
              # the distance in years will come out to over 80 years when in written
              # english it would read better as about 80 years.
              minutes_with_offset         = distance_in_minutes - minute_offset_for_leap_year
              remainder                   = (minutes_with_offset % 525600)
              distance_in_years           = (minutes_with_offset / 525600)
              if remainder < 131400
                locale.t(:about_x_years,  count: distance_in_years)
              elsif remainder < 394200
                locale.t(:over_x_years,   count: distance_in_years)
              else
                locale.t(:almost_x_years, count: distance_in_years + 1)
              end
          end
        end
      end

      def time_ago_in_words(from_time, fix_time_zone = false, include_seconds = false)
        return unless from_time
        from_time = from_time + 8.hours if fix_time_zone
        right_now = in_pst(Time.now)
        from_time = in_pst(from_time)
        qualifier = (from_time < right_now) ? 'ago' : 'from now'
        distance  = distance_of_time_in_words(from_time, right_now, include_seconds)
        "#{distance} #{qualifier}"
      end
      alias_method :distance_of_time_in_words_to_now, :time_ago_in_words

      def date_in_pst(time)
        as_date(in_pst(time))
      end

      def as_date(time)
        return unless time
        Date.new(time.year, time.month, time.day)
      end

      def in_pst(time)
        return unless time
        time.to_time.in_time_zone('Pacific Time (US & Canada)')
      end

      def formatted_time(time, fmt = '%a, %b %d, %Y @ %I:%M:%S%p')
        return unless time
        in_pst(time).strftime(fmt)
      end
    end
  end
end