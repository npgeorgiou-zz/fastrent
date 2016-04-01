class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def purple
    colorize(35)
  end

  def light_blue
    colorize(36)
  end

  def replace (placeholder, value)
    return self.gsub('#{' + placeholder + '}', value.to_s)
  end

  def get_between (start_str, end_str)
    self[/#{Regexp.escape(start_str)}(.*?)#{Regexp.escape(end_str)}/m, 1]
  end


end