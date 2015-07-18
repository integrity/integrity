# Helper methods defined here can be accessed in any controller or view in the application

module Integrity
  module Helpers
    module PancakesHelper
      def human_state_row_color_class(stack)
        if stack.off?
          ''
        elsif stack.running?
          'success'
        elsif stack.starting? || stack.stopping?
          'warning'
        else
          'danger'
        end
      end

      def launch_button(commit, disabled: false)
        unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        launch_button_helper(commit.codebase.capitalize, "http://#{unit.tcp_str}", disabled)
      end

      def launch_button_helper(service_name, url, disabled)
        link_to "Launch #{service_name}", url, target: '_blank', class: "btn btn-primary#{disabled ? ' disabled' : ''} launch-btn"
      end

      def tcp_string(commit)
        unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        if unit && unit.tcp_str
          unit.tcp_str
        else
          ''
        end
      end

      def mailcatcher_url(unit)
        return nil unless unit && unit.active?
        format('http://%s:%d', unit.machine_ip, unit.port)
      end

      def mailcatcher_button(unit, disabled: false)
        launch_button_helper('Mailcatcher', mailcatcher_url(unit), disabled)
      end

      def mysql_str(unit)
        if unit && unit.active?
          mysql_connect_str(unit) + '<br>' + mysql_url(unit)
        else
          'mysql not running'
        end
      end

      def mysql_connect_str(unit)
        if unit && unit.active?
          format('mysql -uroot -h%s -P%d -Dgrh-development', unit.machine_ip, unit.port)
        else
          ''
        end
      end

      def mysql_url(unit)
        if unit && unit.active?
          format('mysql://root@%s:%d', unit.machine_ip, unit.port)
        else
          ''
        end
      end

      def postgres_str(unit)
        if unit && unit.active?
          postgres_connect_str(unit) + '<br>' + postgres_url(unit)
        else
          'postgres not running'
        end
      end

      def postgres_connect_str(unit)
        if unit && unit.active?
          format('psql -Upostgres -h%s -p%d -dpg-cache-development', unit.machine_ip, unit.port)
        else
          ''
        end
      end

      def postgres_url(unit)
        if unit && unit.active?
          format('postgres://root@%s:%d/pg-cache-development', unit.machine_ip, unit.port)
        else
          ''
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
    end
  end
end
