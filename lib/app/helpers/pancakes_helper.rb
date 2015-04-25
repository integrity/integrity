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
        cb = commit.codebase
        if unit && !unit.tcp_str.empty?
          link_to cb, "http://#{unit.tcp_str}", target: '_blank'
        else
          cb
        end
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
        if unit && unit.active?
          link_to 'mailcatcher', mailcatcher_url(unit), target: '_blank'
        else
          'mailcatcher not running'
        end
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
