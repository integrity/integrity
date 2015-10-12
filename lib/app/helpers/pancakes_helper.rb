# Helper methods defined here can be accessed in any controller or view in the application

module Integrity
  module Helpers
    module PancakesHelper
      def health_check_bootstrap_class(health_check)
        if !health_check
          'default'
        elsif health_check.healthy?
          'success'
        else
          'danger'
        end
      end

      def event_status_bootstrap_class(event_status)
        if !event_status
          'default'
        elsif [HonestyCluster::HealthCheck::STATUS_HEALTHY].include?(event_status)
          'success'
        elsif [HonestyCluster::HealthCheck::STATUS_UNHEALTHY].include?(event_status)
          'danger'
        else
          'default'
        end
      end

      #def container_status_bootstrap_class(container)
        #if !container
          #'warning'
        #elsif container.running?
          #'success'
        #elsif container.failed?
          #'danger'
        #elsif container.exited?
          #'success'
        #else
          #'warning'
        #end
      #end

      def health_check_timestamp(health_check)
        health_check ? time_ago_in_words(health_check.timestamp) : ''
      end

      def health_check_str(health_check)
        health_check ? health_check.health_str : 'HEALTH_UNKNOWN'
      end

      def health_check_message(health_check)
        health_check ? health_check.message : 'resource created'
      end

      def poc_string(pocs)
        pocs ? pocs.join(', ') : ''
      end

      def event_message(event)
        event ? event.message : ''
      end

      def container_state(container)
        container ? container.status : ''
      end

      def http_url(unit)
        _tcp_str =
          if unit.service_name == 'mailcatcher'
            if public_port = unit.lookup_public_port(1080)
              unit.tcp_str(public_port)
            else
              nil
            end
          else
            unit.tcp_str
          end
        _tcp_str ? "http://#{_tcp_str}" : nil
      end

      #def launch_button(text, url, enabled: true)
      def launch_button(unit, last_health_check)
        text    = unit.codebase || unit.service_name
        url     = http_url(unit)
        enabled = last_health_check && last_health_check.healthy?
        launch_button_helper(
          text,
          url,
          enabled,
        )
      end

      #def launch_button(commit, disabled: false)
        #unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        #launch_button_helper(commit.codebase.capitalize, "http://#{unit.tcp_str}", disabled)
      #end

      def launch_button_helper(service_name, url, enabled)
        link_to "Launch #{service_name}", url, target: '_blank', class: "#{enabled ? '' : 'disabled'} launch-btn"
      end

      #def tcp_string(commit)
        #unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        #if unit && unit.tcp_str
          #unit.tcp_str
        #else
          #''
        #end
      #end

      def service_notes(unit, last_health_check)
        if last_health_check && last_health_check.healthy?
          if unit.addr_known?
            if unit.service_name == 'mysql'
              [
                mysql_notes(unit),
              ]
            elsif unit.service_name == 'postgres'
              [
                postgres_notes(unit),
              ]
            else
              [
                http_url(unit),
              ]
            end
          else
            [
              "Last health was fine, but the service is missing it's address. Refresh the health.",
            ]
          end
        else
          [
            health_check_message(last_health_check)
          ]
        end
          .flatten
          .compact
      end

      def mailcatcher_url(unit)
        return nil unless unit && unit.active?
        format('http://%s:%d', unit.machine_ip, unit.port)
      end

      #def mailcatcher_button(unit, disabled: false)
        #launch_button_helper('Mailcatcher', mailcatcher_url(unit), disabled)
      #end

      def mysql_notes(unit)
        if unit
          [
            mysql_connect_str(unit),
            mysql_url(unit),
          ]
        else
          nil
        end
      end

      def mysql_connect_str(unit)
        if unit && unit.active?
          format('mysql -uroot -h%s -P%d -Dgrh-development', unit.machine_ip, unit.port)
        else
          nil
        end
      end

      def mysql_url(unit)
        if unit && unit.active?
          format('mysql://root@%s:%d', unit.machine_ip, unit.port)
        else
          nil
        end
      end

      def postgres_notes(unit)
        if unit
          [
            postgres_connect_str(unit),
            postgres_url(unit),
          ]
        else
          nil
        end
      end

      def postgres_connect_str(unit)
        if unit && unit.active?
          format('psql -Upostgres -h%s -p%d -dpg-cache-development', unit.machine_ip, unit.port)
        else
          nil
        end
      end

      def postgres_url(unit)
        if unit && unit.active?
          format('postgres://root@%s:%d/pg-cache-development', unit.machine_ip, unit.port)
        else
          nil
        end
      end

      def uptime(stack)
        if stack && stack.running?
          time_ago_in_words(stack.state_updated_at).sub(' ago', '')
        else
          ''
        end
      end

      def services_for_form
        %w[jarvis frick tim tp banyan]
      end

      def pk_build_bootstrap_class(build)
        if build
          build.bootstrap_class
        else
          ''
        end
      end

      def build_notes(build)
        if build
          "bulid status: #{build.status}"
        else
          "build not found"
        end
      end
    end
  end
end
