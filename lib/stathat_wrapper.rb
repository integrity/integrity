class StatHatWrapper
  @enabled = true
  @ez_key = nil

  def self.enable
    @enabled = true
  end

  def self.disable
    @enabled = false
  end

  def self.ez_key=(key)
    @ez_key = key
  end

  def self.post_count(name, count)
    if @enabled
      StatHat::API.ez_post_count(name, @ez_key, count)
    else
      logger.info "[stathat] pretend StatHat ez_post_count: stat='#{name}' count=#{count}"
    end
  end

  def self.post_value(name, value)
    if @enabled
      StatHat::API.ez_post_value(name, @ez_key, value)
    else
      logger.info "[stathat] pretend StatHat ez_post_value: stat='#{name}' value=#{value}"
    end
  end

  # @api private
  def self.logger
    Integrity.logger
  end
end
