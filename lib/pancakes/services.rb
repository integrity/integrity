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
        image: 'grnds/mysql:latest',
        netmaster: true,
        ports: [3306],
        requires: 'docker.service',
      },
      {
        name: 'postgres',
        image: 'grnds/postgres:latest',
        ports: [5432],
        machineof: :mysql,
        requires: 'docker.service',
      },
      {
        name: 'mailcatcher',
        image: 'grnds/mailcatcher:latest',
        requires: :mysql,
        machineof: :mysql,
        ports: [1080,1025],
      },
      {
        name: 'freezer',
        chore: true,
        image: 'grnds/freezer:latest',
        requires: :mysql,
        machineof: :mysql,
        env: SERVICE_ENV,
      },
      {
        name: 'frick-server',
        repo: 'consultingmd/frick',
        image: 'grnds/frick_ci:latest',
        machineof: :mysql,
        requires: :mysql,
        ports: [10002],
        ping_url: 'http://$ip:$port/status',
        env: SERVICE_ENV,
        dbs: %w[frick-development ruote-development],
      },
      {
        name: 'jarvis-orchestra',
        image: 'grnds/jarvis_ci:latest',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :mysql,
        env: SERVICE_ENV,
        dbs: %w[grh-development],
      },
      {
        name: 'jarvis-server',
        image: 'grnds/jarvis_ci:latest',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        ports: [10001],
        ping_url: 'http://$ip:$port/status',
        env: SERVICE_ENV,
      },
      {
        name: 'jarvis-delayed_job',
        image: 'grnds/jarvis_ci:latest',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        env: SERVICE_ENV,
      },
      {
        name: 'tim-orchestra',
        image: 'grnds/tim_ci:latest',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :mysql,
        env: SERVICE_ENV,
        dbs: %w[tim-development],
      },
      {
        name: 'tim-server',
        image: 'grnds/tim_ci:latest',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        ports: [10004],
        ping_url: 'http://$ip:$port/status',
        env: SERVICE_ENV,
      },
      {
        name: 'tim-delayed_job',
        image: 'grnds/tim_ci:latest',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        env: SERVICE_ENV,
      },
      {
        name: 'tp-server',
        image: 'grnds/tp_ci:latest',
        repo: 'consultingmd/tp',
        machineof: :mysql,
        requires: :mysql,
        env: SERVICE_ENV,
        ports: [10003],
        ping_url: 'http://$ip:$port/status',
        dbs: %w[tp_dev],
      },
      {
        name: 'banyan-server',
        image: 'grnds/banyan_ci:latest',
        repo: 'consultingmd/banyan',
        machineof: :mysql,
        requires: :mysql,
        env: SERVICE_ENV,
        ports: [10010],
        ping_url: 'http://$ip:$port/status',
        dbs: %w[pg-cache-development],
      },
    ]

    def get(service_name)
      SERVICE_DEFS.detect{|service_def| service_def[:name] == service_name.to_s } || raise("no service by the name of #{service_name}")
    end

    def jarvis_services
      #SERVICE_DEFS.select{|s| !s[:chore] }.map{|s| s[:name] }
      %w[mysql mailcatcher jarvis-server jarvis-orchestra jarvis-delayed_job tim-server tim-orchestra tim-delayed_job frick-server]
    end

    def tp_services
      jarvis_services + %w[tp-server]
    end

    def banyan_services
      jarvis_services + %w[banyan-server postgres]
    end

    def netmaster
      SERVICE_DEFS.each do |service_def|
        if service_def[:netmaster] == true
          return service_def[:name]
        end
      end

      raise 'no netmaster is specified'
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
