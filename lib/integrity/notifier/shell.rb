
module Integrity
  class Notifier
    class Shell < Notifier::Base
      def self.to_haml
        <<-HAML
%p.normal
  %label{ :for => "build_success" } On build success
  %input.text#build_success{                       |
    :name => "notifiers[Shell][success_script]",   |
    :type => "text",                               |
    :value => config["success_script"] || "" }     |
%p.normal
  %label{ :for => "build_failed" } On build fail
  %input.text#build_failed{                 |
    :name => "notifiers[Shell][failed_script]",    |
    :type => "text",                               |
    :value => config["failed_script"] ||  "" }     |
%p.normal
  %label{ :for => "shell_announce_success" } Notify on success?
  %input#shell_announce_success{                                |
    :name => "notifiers[Shell][announce_success]",              |
    :type => "checkbox",                                        |
    :checked => config['announce_success'], :value => "1" }     |
        HAML
      end

      def initialize(build, config={})
        @success_cmd = config.delete("success_script")
        @failed_cmd = config.delete("failed_script")
        super
      end

      def deliver!
        @cmd = build.successful? ? @success_cmd : @failed_cmd
        `#{@cmd}`
      end

      private
        def announce_build?
          build.failed? || config["announce_success"]
        end
    end

    register Shell
  end
end
