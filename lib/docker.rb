class Docker
  include Runnable
  include Utilities

  attr_reader :token, :running

  def initialize(directory, logger)
    super
    @token   = generate_sha1(timestamp)
    @running = {}

  end

  def make_tmp_dir!
    runner.run! "mkdir -p #{directory}"
  end

  def fetch_file!(file)
    token = github_token
    acct  = github_account
    repo  = 'tp' #@build.repo
    cmd   = Commands.fetch_file token, acct, repo, file
    puts cmd
    run_in_dir!(cmd)
  end

  def get_build_script_template!
    fetch_file! '.integrity.erb'
  end

  def process_erb!
    template = ERB.new(File.new("#{directory}/.integrity.erb").read, nil, '%')
    sh_commands = template.result(binding)
    puts sh_commands
    sh_file = "#{directory}/integrity.sh"
    puts sh_file
    File.open(sh_file, 'w'){|f| f.write(sh_commands) }
  end

  def run(image, &block)
    cmd = case image
      when :mysql
        uuid = "mysql-#{timestamp}"
        running[:mysql] = uuid
        puts 'running mysql image...'
        Commands.docker_run_mysql(uuid)
      when :image
        running[:image] = token
        mysql = running[:mysql].presence || 'mysql'
        puts 'running ubuntu image...'
        Commands.docker_run_image(mysql, token)
      else
        running[image]  = token
        Commands.docker_run(image, token)
      end

    puts cmd
    run_in_dir(cmd, &block)
  end

  def build!
    make_tmp_dir!
    get_build_script_template!
    process_erb!
    create_docker_file!
    cmd = Commands.docker_build(token)
    puts 'Building docker image...'
    puts cmd
    run_in_dir!(cmd) do |out|
      puts out
    end
  end

  def github_token
    Integrity.config.github_token
  end

  def github_account
    Integrity.config.github_account
  end

  def create_docker_file!
    puts 'Getting Dockerfile...'
    fetch_file! 'Dockerfile'
    # puts 'Making Dockerfile...'
    # in_dir do
    #   runner.run! 'echo "FROM grnds/tp" >> Dockerfile'
    #   runner.run! 'echo "MAINTAINER ops@grnds.com" >> Dockerfile'
    #   runner.run! 'echo "USER root" >> Dockerfile'
    #   runner.run! 'echo "ADD integrity.sh /usr/local/bin/integrity.sh" >> Dockerfile'
    #   runner.run! 'echo "RUN chmod +x /usr/local/bin/integrity.sh" >> Dockerfile'
    #   runner.run! 'echo "ENTRYPOINT /usr/local/bin/integrity.sh" >> Dockerfile'
    # end
    # puts 'Dockerfile done.'
  end
end