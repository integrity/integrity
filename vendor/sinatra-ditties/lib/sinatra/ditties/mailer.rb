# Shamelssly stolen from Merb::Mailer
# http://merbivore.com

require 'net/smtp'
require 'rubygems'
require 'mailfactory'
require 'tlsmail'

Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)

class MailFactory
  attr_reader :html, :text
end

module Sinatra
  # = Sinatra::Mailer
  #
  # Adds an #email method to your email handlers, that receives a hash of
  # values to create your email.
  #
  # For example:
  #
  #   post "/signup" do
  #     # sign up the user, and then:
  #     email :to      => @user.email,
  #           :from    => "awesomeness@example.com",
  #           :subject => "Welcome to Awesomeness!",
  #           :body    => haml(:some_template)
  #   end
  #
  # == Configuration
  #
  # This plugin is very dirty yet :) Since it's just a port to Sinatra of
  # Merb::Mailer[merbivore.com/documentation/1.0/doc/rdoc/merb-mailer-1.0].
  # So the configuration is not Sinatra-y, yet. But we'll get to that.
  #
  # == Using SMTP
  #
  #  Sinatra::Mailer.config = {
  #    :host   => 'smtp.yourserver.com',
  #    :port   => '25',
  #    :user   => 'user',
  #    :pass   => 'pass',
  #    :auth   => :plain # :plain, :login, :cram_md5, the default is no auth
  #    :domain => "localhost.localdomain" # HELO domain provided by the client
  #  }
  #
  # == Using Gmail SMTP
  #
  # You need smtp-tls[http://github.com/ambethia/smtp-tls], a gem that improves
  # Net::HTTP to add support for secure servers such as Gmail.
  #
  #  require "smtp-tls"
  #
  #  Sinatra::Mailer.config = {
  #    :host => 'smtp.gmail.com',
  #    :port => '587',
  #    :user => 'user@gmail.com',
  #    :pass => 'pass',
  #    :auth => :plain
  #  }
  #
  # Make sure that when you call your #email method you pass the
  # +:text+ option and not +:body+.
  #
  # == Using sendmail
  #
  #  Sinatra::Mailer.config = {:sendmail_path => '/somewhere/odd'}
  #  Sinatra::Mailer.delivery_method = :sendmail
  #
  # == Credits
  #
  # This has been blatantly adapted from
  # Merb::Mailer[merbivore.com/documentation/1.0/doc/rdoc/merb-mailer-1.0]
  # so all credit is theirs, I just ported it to Sinatra.
  module Mailer
    class << self
      attr_accessor :config, :delivery_method
    end

    def email(mail_options={})
      Email.new(mail_options).deliver!
    end

    class Email
      attr_accessor :mail, :config

      # Sends the mail using sendmail.
      def sendmail
        sendmail = IO.popen("#{config[:sendmail_path]} #{@mail.to}", 'w+')
        sendmail.puts @mail.to_s
        sendmail.close
      end

      # Sends the mail using SMTP.
      def net_smtp
        Net::SMTP.start(config[:host], config[:port].to_i, config[:domain],
                        config[:user], config[:pass], config[:auth]) { |smtp|
          smtp.send_message(@mail.to_s, @mail.from.first, @mail.to.to_s.split(/[,;]/))
        }
      end

      # Delivers the mail with the specified delivery method, defaulting to
      # net_smtp.
      def deliver!
        send(Mailer.delivery_method || :net_smtp)
      end

      # ==== Parameters
      # file_or_files<File, Array[File]>:: File(s) to attach.
      # filename<String>::
      # type<~to_s>::
      #   The attachment MIME type. If left out, it will be determined from
      #   file_or_files.
      # headers<String, Array>:: Additional attachment headers.
      #
      # ==== Raises
      # ArgumentError::
      #   file_or_files was not a File or an Array of File instances.
      def attach(file_or_files, filename = file_or_files.is_a?(File) ? File.basename(file_or_files.path) : nil,
        type = nil, headers = nil)
        if file_or_files.is_a?(Array)
          file_or_files.each {|k,v| @mail.add_attachment_as k, *v}
        else
          raise ArgumentError, "You did not pass in a file. Instead, you sent a #{file_or_files.class}" if !file_or_files.is_a?(File)
          @mail.add_attachment_as(file_or_files, filename, type, headers)
        end
      end

      # ==== Parameters
      # o<Hash{~to_s => Object}>:: Configuration commands to send to MailFactory.
      def initialize(o={})
        self.config = Mailer.config || {:sendmail_path => '/usr/sbin/sendmail'}
        o[:rawhtml] = o.delete(:html)
        m = MailFactory.new()
        o.each { |k,v| m.send "#{k}=", v }
        @mail = m
      end

    end
  end

  class EventContext
    include Mailer
  end
end
