module Integrity
  class Notifier
    class Email < Notifier::Base
      attr_reader :to, :from

      def self.to_haml
        <<-EOF
%p.normal
  %label{ :for => "email_notifier_to" } Send to
  %input.text#email_notifier_to{ :name => "notifiers[Email][to]", :type => "text", :value => config["to"] }

%p.normal
  %label{ :for => "email_notifier_from" } Send from
  %input.text#email_notifier_from{ :name => "notifiers[Email][from]", :type => "text", :value => config["from"] }

%h3 SMTP Server Configuration

%p.normal
  %label{ :for => "email_notifier_host" } Host : Port
  = succeed " : " do
    %input.text#email_notifier_host{ :name => "notifiers[Email][host]", :value => config["host"], :style => "width: 24.5em;", :type => "text" }
  %input.text#email_notifier_port{ :name => "notifiers[Email][port]", :value => config["port"], :style => "width: 3.5em;", :type => "text" }

%p.normal
  %label{ :for => "email_notifier_user" } User
  %input.text#email_notifier_user{ :name => "notifiers[Email][user]", :value => config["user"], :type => "text" }

%p.normal
  %label{ :for => "email_notifier_pass" } Password
  %input.text#email_notifier_pass{ :name => "notifiers[Email][pass]", :value => config["pass"], :type => "text" }

%p.normal
  %label{ :for => "email_notifier_auth" } Auth type
  %input.text#email_notifier_auth{ :name => "notifiers[Email][auth]", :value => (config["auth"] || "plain"), :type => "text" }

%p.normal
  %label{ :for => "email_notifier_domain" } Domain
  %input.text#email_notifier_domain{ :name => "notifiers[Email][domain]", :value => config["domain"], :type => "text" }
EOF
      end

      def initialize(build, config={})
        @to     = config.delete("to")
        @from   = config.delete("from")
        super
      end

      def deliver!
      end
    end
  end
end
