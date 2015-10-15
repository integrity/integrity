module HonestyCluster
  module SwarmBackend
    extend self

    IP_ADDR_REGEX = /(?<ip>\d{1,3}(?:\.\d{1,3}){3})/

    class Node
      attr_reader :ip

      def initialize(ip)
        @ip = ip
      end

      def systemd_name
        raise('must implement')
      end

      def ssh(cmd=nil)
        system(["ssh core@#{ip}", cmd].flatten.join(' '))
      end

      def restart
        ssh("sudo systemctl restart #{systemd_name}")
      end
    end

    class Master < Node
      def systemd_name
        'swarm-master'
      end
    end

    class Minion < Node
      def systemd_name
        'swarm-minion'
      end
    end

    def base_url
      Integrity.base_url
    end

    def master_ip
      ENV['DOCKER_HOST'].match(IP_ADDR_REGEX)[:ip]
    end

    def node_count
      if HonestyCluster.dry_run?
        1
      else
        docker_info.DriverStatus.detect{|e| e[0].match(/Nodes/) }.last.to_i
      end
    end

    def node_info
      # drop some useless info
      nodes = docker_info.DriverStatus.drop(4)
      # chunk the node info together
      nodes = (nodes.size/5).times.map.with_index{|_,i| [nodes.drop(i*5).take(5)] }
      # clean up non-ascii and transform to hash
      nodes = nodes.map{|e| e.first.map{|k,v| [rm_non_ascii(k).strip, v] } }.map(&:to_h)
    end

    def master
      Minion.new(master_ip)
    end

    def minions
      node_info.map do |node|
        Minion.new(
          node.values.detect do |val|
            val.split(':')[0].match(IP_ADDR_REGEX)
          end.split(':')[0]
        )
      end
    end

    def rm_non_ascii(non_ascii_string)
      encoding_options = {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :universal_newline => true       # Always break lines with \n
      }
      non_ascii_string.encode(Encoding.find('ASCII'), encoding_options)
    end

    def docker_info
      if HonestyCluster.dry_run?
        {}
      else
        Hashie::Mash.new(Docker.info)
      end
    end

    def restart_minions
      minions.map(&:restart)
    end

    #def get_unit_from_container(container_name)
      #unit_info = Pancakes::Unit.parse_unit_name(container_name)
      #Pancakes::Unit.where(stack_id: unit_info.stack_id, service_name: unit_info.service_name).first
    #end
  end
end
