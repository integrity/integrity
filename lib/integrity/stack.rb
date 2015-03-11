require 'fileutils'

module Integrity
  class Stack

    STATIC_PREFIX = 'pancakes'
    TEMPLATES_DIR = 'services/templates/server'

    attr_reader :stack_id, :build_id, :tags,
      :frick_branch, :frick_sha,
      :jarvis_branch, :jarvis_sha,
      :tim_branch, :tim_sha

    def initialize(args={})
      @build_id      = args[:build_id]
      @frick_branch  = args[:frick][:branch]
      @frick_sha     = args[:frick][:sha]
      @jarvis_branch = args[:jarvis][:branch]
      @jarvis_sha    = args[:jarvis][:sha]
      @tim_branch    = args[:tim][:branch]
      @tim_sha       = args[:tim][:sha]
      @tags          = args[:tags] || []
      @stack_id      = format("%s_%s%s", STATIC_PREFIX, @build_id, tag_string)
    end

    # @param build must be a jarvis build
    def self.make_a_new_one(build, tags=[])
      build_id = build.id
      jarvis_commit = build.commit
      #jarvis_commit = Integrity::Project.first(name: 'jarvis').branches.first(name: 'dockyard').builds.last.commit
      frick_commit = Integrity::Project.first(name: 'frick').branches.first(name: 'dockyard').builds.last.commit
      tim_commit = Integrity::Project.first(name: 'tim').branches.first(name: 'dockyard').builds.last.commit

      new({
        build_id: build_id,
        tags: tags,
        frick:  { branch: frick_commit.branch,  sha: frick_commit.identifier },
        jarvis: { branch: jarvis_commit.branch, sha: jarvis_commit.identifier },
        tim:    { branch: tim_commit.branch,    sha: tim_commit.identifier },
      })
    end

    def self.jarvis_build_at_branch(branch_name)
      Integrity::Project.first(name: 'jarvis').branches.first(name: branch_name).builds.last
    end

    def orchestrate
      bake_erb
      Fleetctl.load(service_files)

      mysql = service_files.select{|f| f.path.include?('mysql') }
      Fleetctl.start(mysql)

      sleep 5

      orchs = service_files.select{|f| f.path.include?('orchestra') }
      Fleetctl.start(orchs)

      sleep 5

      other = service_files.select{|f| !f.path.include?('orchestra') && !f.path.include?('mysql') }
      Fleetctl.start(other)
    end

    # locals/methods needed by the ERB rendering context
    # - stack_id
    # - jarvis_branch
    # - jarvis_sha
    # - frick_branch
    # - frick_sha
    # - tim_branch
    # - tim_sha
    # - github_read_token
    # - aws_access_key_id
    # - aws_secret_access_key
    # - aws_secret_key
    def bake_erb
      github_read_token = ENV['GITHUB_READ_TOKEN']
      aws_access_key_id = ENV['DEV_AWS_ACCESS_KEY_ID']
      aws_secret_access_key = ENV['DEV_AWS_SECRET_ACCESS_KEY']
      aws_secret_key = ENV['DEV_AWS_SECRET_KEY']
      b = binding

      mk_out_dir

      Dir[TEMPLATES_DIR + '/*.erb'].each do |erb_fname|
        contents = ERB.new(File.read(erb_fname)).result(b)
        outf = baked_filename(erb_fname)

        File.open(outf, 'w') do |f|
          f.puts contents
        end
      end

      service_files
    end

    def service_files
      Dir["#{out_dir}/*.service"].map do |file|
        File.open(file, 'r')
      end
    end

    def get_urls
      Fleetctl.sync
      units = Fleetctl.units

      # since all containers in a stack run on the same machine, we can get the worker ip from the first one
      servers = units.select{|u| u.name.include?(@stack_id) && u.name.include?('-server.') }
      if !servers.empty?
        worker_ip = servers.first.ip
      else
        return nil
      end

      setup_docker_api_client(worker_ip)
      net_cont_name = container_name('mysql')

      begin
        net_container = Docker::Container.get(net_cont_name)
        return net_container.info['NetworkSettings']['Ports'].to_a.map do |service_port,host_ports|
          { service_port.to_i => format("http://%s:%d", worker_ip, host_ports.first['HostPort'].to_i) }
        end
      rescue Docker::Error::NotFoundError => e
        Integrity.logger.warn "networking container not found: #{net_cont_name}"
        return nil
      end
    end

    private

    def setup_docker_api_client(addr)
      Docker.url = "tcp://#{addr}:2375"
      Docker.validate_version!
    end

    def tag_string
      return '' if tags.empty?
      "_#{tags.join('_')}"
    end

    def mk_out_dir
      FileUtils.mkdir_p out_dir
    end

    def out_dir
      File.join('/tmp', @stack_id)
    end

    def baked_filename(fname)
      File.join(out_dir, "#{@stack_id}_#{File.basename fname.sub(/\.erb$/, '')}")
    end

    def container_name(service)
      "#{@stack_id}_#{service}"
    end
  end
end
