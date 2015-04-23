module Pancakes
  module Services

    # the first port will be used in the ping_url
    SERVICE_DEFS = [
      {
        name: 'mysql',
        image: 'grnds/mysql',
        netmaster: true,
        ports: [3306],
        requires: 'docker.service',
        env: {
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'mailcatcher',
        image: 'simpledrupalcloud/mailcatcher',
        requires: :mysql,
        machineof: :mysql,
        ports: [80,25],
      },
      {
        name: 'frick-server',
        repo: 'consultingmd/frick',
        image: 'grnds/frick_ci',
        machineof: :mysql,
        requires: :mysql,
        ports: [10002],
        ping_url: 'http://$ip:$port/status',
        env: {
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'jarvis-orchestra',
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :mysql,
        env: {
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'jarvis-server',
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        ports: [10001],
        ping_url: 'http://$ip:$port/status',
        env: {
          'MAILCATCHER_SMTP_PORT' => 25,
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'jarvis-delayed_job',
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        env: {
          'MAILCATCHER_SMTP_PORT' => 25,
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'tim-orchestra',
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :mysql,
        env: {
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'tim-server',
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        ports: [10004],
        ping_url: 'http://$ip:$port/status',
        env: {
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
      {
        name: 'tim-delayed_job',
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        env: {
          'GITHUB_READ_TOKEN'     => true,
          'AWS_ACCESS_KEY_ID'     => true,
          'AWS_SECRET_ACCESS_KEY' => true,
          'AWS_SECRET_KEY'        => true,
        },
      },
    ]

    def self.get(service_name)
      SERVICE_DEFS.detect{|service_def| service_def[:name] == service_name.to_s } || raise("no service by the name of #{service_name}")
    end

    def self.get_with_env(service_name)
      service_def = get(service_name)
      service_def[:env] = service_def[:env].map do |k,v|
        if v == true
          [k, ENV[k]]
        else
          [k, v]
        end
      end.to_h
      service_def
    end

    def self.all_names
      SERVICE_DEFS.map{|s| s[:name] }
    end

    def self.all_ports
      SERVICE_DEFS.map{|s| s[:ports] || [] }.reduce(&:+)
    end

    def self.netmaster
      SERVICE_DEFS.each do |service_def|
        if service_def[:netmaster] == true
          return service_def[:name]
        end
      end

      raise "no netmaster is specified"
    end

    def self.parse_service_name(service_name)
      if service_name['-']
        service_name.split('-')
      else
        service_name
      end
    end
  end
end
