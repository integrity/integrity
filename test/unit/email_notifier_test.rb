require "helper"
#TODO: these 3 must be added to the deps.rip file
require "rumbster"
require "message_observers"
require "sinatra/ditties/mailer"

begin
  require "redgreen"
rescue LoadError
end

require "integrity/notifier/test"
require "integrity/notifier/email"

class IntegrityEmailTest < Test::Unit::TestCase
  include Integrity::Notifier::Test

  MAIL_SERVER_PORT = 10_000

  def notifier
    "Email"
  end

  def setup
    Net::SMTP.disable_tls

    @server        = Rumbster.new(MAIL_SERVER_PORT)
    @mail_observer = MailMessageObserver.new
    @server.add_observer(@mail_observer)

    @server.start

    setup_database
  end

  def commit(status=:successful)
    Integrity::Commit.gen(status)
  end

  def build(status=:successful)
    Integrity::Build.gen(status)
  end

  def teardown
    @server.stop
  end

  def test_configuration_form
    assert form_have_tag?("h3", :content => "SMTP Server Configuration")

    assert provides_option?("to",       "foo@example.org")
    assert provides_option?("from",     "bar@example.org")
    assert provides_option?("host",     "foobarhost.biz")
    assert provides_option?("user",     "foobaruser")
    assert provides_option?("pass",     "secret")
    assert provides_option?("auth",     "plain")
    assert provides_option?("pass",     "secret")
    assert provides_option?("domain",   "localhost")
    assert provides_option?("sendmail", "/usr/sbin/sendmail")
  end

  def test_it_sends_email_notification
    config = { "host" => "127.0.0.1",
               "port" => MAIL_SERVER_PORT,
               "to"   => "you@example.org",
               "from" => "me@example.org"  }

    successful = build(:successful)
    failed     = build(:failed)

    Integrity::Notifier::Email.new(successful, config.dup).deliver!
    Integrity::Notifier::Email.new(failed,     config).deliver!

    assert_equal "net_smtp", Sinatra::Mailer.delivery_method

    mail = @mail_observer.messages.first

    assert_equal ["you@example.org"], mail.destinations
    assert_equal ["me@example.org"],  mail.from
    assert mail.subject.include?("successful")
    assert mail.body.include?(successful.commit.committed_at.to_s)
    assert mail.body.include?(successful.commit.author.name)
    assert mail.body.include?(successful.output)
  end

  def test_it_configures_email_notification_with_sendmail
    sendmail_path = "/usr/sbin/sendmail"

    config = { "sendmail" => sendmail_path,
               "to"   => "sendmail@example.org",
               "from" => "me@example.org"  }
    successful = build(:successful)

    Integrity::Notifier::Email.new(successful, config)

    assert_equal :sendmail, Sinatra::Mailer.delivery_method
    assert_equal sendmail_path, Sinatra::Mailer.config[:sendmail_path]
  end
end
