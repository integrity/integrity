class SendGridWrapper
  @client = SendGrid::Client.new do |c|
    c.api_user = ENV['SENDGRID_USERNAME']
    c.api_key = ENV['SENDGRID_PASSWORD']
  end

  def self.send_mail(to, from, subject, html)
    mail = SendGrid::Mail.new do |m|
      m.to = to
      m.from = from
      m.subject = subject
      m.html = html
    end

    @client.send(mail)
  end
end
