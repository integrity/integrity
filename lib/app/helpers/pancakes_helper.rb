# Helper methods defined here can be accessed in any controller or view in the application

module Integrity
  module Helpers
    module PancakesHelper
      def event_bootstrap_class(event)
        if !event
          ''
        elsif event.complete?
          'success'
        elsif event.in_progress?
          'warning'
        elsif event.failed?
          'danger'
        else
          ''
        end
      end

      def container_status_bootstrap_class(container)
        if !container
          'danger'
        elsif container.running?
          'success'
        elsif container.failed?
          'danger'
        elsif container.exited?
          'success'
        else
          'danger'
        end
      end

      def event_status(event)
        event ? event.status : ''
      end

      def event_timestamp(event)
        event ? time_ago_in_words(event.created_at) : ''
      end

      def poc_string(pocs)
        pocs ? pocs.join(', ') : ''
      end

      def container_state(container)
        container ? container.status : '?'
      end

      def http_url(unit)
        _tcp_str =
          if unit.service_name == 'mailcatcher'
            if public_port = unit.lookup_public_port(1080)
              unit.tcp_str(public_port)
            else
              "wtf"
            end
          else
            unit.tcp_str
          end
        _tcp_str ? "http://#{_tcp_str}" : nil
      end

      def launch_button(text, url, enabled: true)
        launch_button_helper(text, url, enabled)
      end

      #def launch_button(commit, disabled: false)
        #unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        #launch_button_helper(commit.codebase.capitalize, "http://#{unit.tcp_str}", disabled)
      #end

      def launch_button_helper(service_name, url, enabled)
        link_to "Launch #{service_name}", url, target: '_blank', class: "btn btn-sm btn-primary#{enabled ? '' : ' disabled'} launch-btn"
      end

      #def tcp_string(commit)
        #unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        #if unit && unit.tcp_str
          #unit.tcp_str
        #else
          #''
        #end
      #end

      def service_notes(unit)
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
        end.flatten.compact
      end

      def mailcatcher_url(unit)
        return nil unless unit && unit.active?
        format('http://%s:%d', unit.machine_ip, unit.port)
      end

      def mailcatcher_button(unit, disabled: false)
        launch_button_helper('Mailcatcher', mailcatcher_url(unit), disabled)
      end

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

      def service_logs_url(unit)
        "#{Integrity.logs_url}?q=#{unit.name}"
      end
    end
  end
end
