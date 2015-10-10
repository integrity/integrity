module Pancakes
  module Services
    extend self

    # also supported, etcd uris! 'FOOBAR'  => 'etcd:///grnds/keys/FOOBAR',
    SERVICE_ENV = {
      'AWS_SECRET_ACCESS_KEY' => ':DEV_AWS_SECRET_ACCESS_KEY',
      'AWS_SECRET_KEY'        => ':DEV_AWS_SECRET_KEY',
      'AWS_ACCESS_KEY_ID'     => ':DEV_AWS_ACCESS_KEY_ID',
      'DICOMGRID_LOGIN'       => ':self',
      'DICOMGRID_PASSWORD'    => ':self',
      'GITHUB_READ_TOKEN'     => ':self',
      'SEND_WITH_US_API_KEY'  => ':self',
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
        ping_url: 'http://$ip:$port/',
        http_status: 200,
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
        http_status: 200,
        env: SERVICE_ENV,
        dbs: %w[frick-development ruote-development],
      },
      {
        name: 'jarvis-setup',
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
        requires: :"jarvis-setup",
        ports: [10001],
        ping_url: 'http://$ip:$port/status',
        http_status: 200,
        env: SERVICE_ENV,
      },
      {
        name: 'jarvis-delayed_job',
        image: 'grnds/jarvis_ci:latest',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-setup",
        env: SERVICE_ENV,
      },
      {
        name: 'tim-setup',
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
        requires: :"tim-setup",
        ports: [10004],
        ping_url: 'http://$ip:$port/status',
        http_status: 200,
        env: SERVICE_ENV,
      },
      {
        name: 'tim-delayed_job',
        image: 'grnds/tim_ci:latest',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-setup",
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
        http_status: 200,
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
        ping_url: 'http://$ip:$port/',
        http_status: 302,
        dbs: %w[pg-cache-development],
      },
      {
        name: 'wp-server',
        image: 'grnds/wp_ci:latest',
        repo: 'consultingmd/wp',
        env: SERVICE_ENV,
        ports: [10009],
        ping_url: 'http://$ip:$port/',
        http_status: 200,
      },
    ]

    def get(service_name)
      SERVICE_DEFS.detect{|service_def| service_def[:name] == service_name.to_s } || raise("no service by the name of #{service_name}")
    end

    def get_by_port(port)
      port = port.to_i
      SERVICE_DEFS.detect{|service_def| service_def[:ports] && service_def[:ports].include?(port) } || raise("no service with the port #{port}")
    end

    def jarvis_services
      %w[mysql mailcatcher jarvis-server jarvis-setup jarvis-delayed_job tim-server tim-setup tim-delayed_job frick-server]
    end

    def tp_services
      jarvis_services + %w[tp-server]
    end

    def banyan_services
      jarvis_services + %w[banyan-server postgres]
    end

    def full_services
      %w[
        mysql postgres mailcatcher
        jarvis-server jarvis-setup jarvis-delayed_job
        tim-server tim-setup tim-delayed_job
        frick-server
        tp-server
        banyan-server
        wp-server
      ]
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
