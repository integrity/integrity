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

      def service_link(commit)
        unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        link_to "Launch #{commit.codebase.capitalize}", "http://#{unit.tcp_str}", target: '_blank', class: "btn btn-primary#{(unit && !unit.tcp_str.empty?) ? '' : ' disabled'}"
      end

      def tcp_string(commit)
        unit = commit.stack.unit_with_service_name("#{commit.codebase.to_s}-server")
        if unit && !unit.tcp_str.empty?
          unit.tcp_str
        else
          ''
        end
      end

      def mailcatcher_url(unit)
        return nil unless unit && unit.active?
        format('http://%s:%d', unit.machine_ip, unit.port)
      end

      def mailcatcher_str(unit)
        link_to 'Launch Mailcatcher', mailcatcher_url(unit), target: '_blank', class: "btn btn-primary #{(unit && unit.active?) ? '' : 'disabled'}"
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
          format('mysql -uroot -h%s -P%d', unit.machine_ip, unit.port)
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

      def uptime(stack)
        if stack && stack.running?
          time_ago_in_words(stack.started_at).sub(' ago', '')
        else
          ''
        end
      end
    end
  end
end
