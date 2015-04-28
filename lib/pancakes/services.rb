module Pancakes
  module Services
    extend self

    SERVICE_ENV = {
      'GITHUB_READ_TOKEN'     => ':self',
      'AWS_ACCESS_KEY_ID'     => ':DEV_AWS_ACCESS_KEY_ID',
      'AWS_SECRET_ACCESS_KEY' => ':DEV_AWS_SECRET_ACCESS_KEY',
      'AWS_SECRET_KEY'        => ':DEV_AWS_SECRET_KEY',
    }

    # conventions
    # - the first port will be used in the ping_url
    SERVICE_DEFS = [
      {
        name: 'mysql',
        image: 'grnds/mysql',
        netmaster: true,
        ports: [3306],
        requires: 'docker.service',
      },
      {
        name: 'mailcatcher',
        image: 'grnds/mailcatcher',
        requires: :mysql,
        machineof: :mysql,
        ports: [1080,1025],
      },
      {
        name: 'frick-server',
        repo: 'consultingmd/frick',
        image: 'grnds/frick_ci',
        machineof: :mysql,
        requires: :mysql,
        ports: [10002],
        ping_url: 'http://$ip:$port/status',
        env: SERVICE_ENV,
      },
      {
        name: 'jarvis-orchestra',
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :mysql,
        env: SERVICE_ENV,
      },
      {
        name: 'jarvis-server',
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        ports: [10001],
        ping_url: 'http://$ip:$port/status',
        env: SERVICE_ENV,
      },
      {
        name: 'jarvis-delayed_job',
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        env: SERVICE_ENV,
      },
      {
        name: 'tim-orchestra',
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :mysql,
        env: SERVICE_ENV,
      },
      {
        name: 'tim-server',
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        ports: [10004],
        ping_url: 'http://$ip:$port/status',
        env: SERVICE_ENV,
      },
      {
        name: 'tim-delayed_job',
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        env: SERVICE_ENV,
      },
    ]

    def get(service_name)
      SERVICE_DEFS.detect{|service_def| service_def[:name] == service_name.to_s } || raise("no service by the name of #{service_name}")
    end

    def all_names
      SERVICE_DEFS.map{|s| s[:name] }
    end

    def all_ports
      SERVICE_DEFS.map{|s| s[:ports] || [] }.reduce(&:+)
    end

    def netmaster
      SERVICE_DEFS.each do |service_def|
        if service_def[:netmaster] == true
          return service_def[:name]
        end
      end

      raise "no netmaster is specified"
    end

    def parse_service_name(service_name)
      if service_name['-']
        service_name.split('-')
      else
        service_name
      end
    end
  end
end
