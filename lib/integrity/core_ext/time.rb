class Time
  alias :strftime_without_ordinals :strftime
  def strftime(format_string)
    format_string.gsub! "%o", case day
      when 1, 21, 31 then "st"
      when 2, 22     then "nd"
      when 3, 23     then "rd"
      else                "th"
    end
    
    strftime_without_ordinals(format_string)
  end
end