require 'rconfig'

class Configuration
  attr_accessor :api_user,
                :api_key,
                :sender_email_address
end

class SendGridWrapper
  def self.send_mail(to, subject, html)
    mail = SendGrid::Mail.new do |m|
      m.to = to
      m.from = config.sender_email_address
      m.subject = subject
      m.html = html
    end

    client.send(mail)
  end

  private

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.client
    client = SendGrid::Client.new do |c|
      c.api_user = config.api_user
      c.api_key = config.api_key
    end
  end
end
