class StatHatWrapper
  @enabled = true
  @ez_key = ENV['STATHAT_EZ_KEY']

  def self.enable
    logger.info 'enabling stathat'
    @enabled = true
  end

  def self.disable
    logger.info 'disabling stathat'
    @enabled = false
  end

  def self.post_count(name, count)
    if @enabled
      StatHat::API.ez_post_count(name, @ez_key, count)
    else
      logger.info "pretend StatHat ez_post_count: stat='#{name}' count=#{count}"
    end
  end

  def self.post_value(name, value)
    if @enabled
      StatHat::API.ez_post_value(name, @ez_key, value)
    else
      logger.info "pretend StatHat ez_post_value: stat='#{name}' value=#{value}"
    end
  end

  # @api private
  def self.logger
    Logging.logger['stathat'].appenders = Logging.appenders.stdout(layout: ::Logging::Layouts::Pattern.new(pattern: "%.1l %d %h %c: %m\n"))
    Logging.logger['stathat'].level = :info
    Logging.logger['stathat']
  end
end
