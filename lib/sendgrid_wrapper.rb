require 'rconfig'
require 'hashie'

class SendGridWrapper
  @@config =
    Hashie::Mash.new(
      api_user: nil,
      api_key: nil,
      sender_email_address: nil,
    )

  def self.config
    @@config
  end

  def self.configure
    yield @@config

    [
      %w[api_user],
      %w[api_key],
      %w[sender_email_address],
    ].each{|keys| !keys.reduce(@@config){|memo,key| memo && memo[key] }.nil? || raise("SendGridWrapper.config.#{keys.join('.')} is required") }
  end

  def self.send_mail(to, subject, html)
    return if Integrity.config.dtest?

    mail = SendGrid::Mail.new do |m|
      m.to = to
      m.from = config.sender_email_address
      m.subject = subject
      m.html = html
    end

    client.send(mail)
  end

  private

  def self.client
    client = SendGrid::Client.new do |c|
      c.api_user = config.api_user
      c.api_key = config.api_key
    end
  end
end
