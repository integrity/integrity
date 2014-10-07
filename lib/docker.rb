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
    run_in_dir!(cmd)
  end

  def get_build_script_template!
    fetch_file! '.integrity.erb'
  end

  def process_erb!
    template = ERB.new(File.new("#{directory}/.integrity.erb").read, nil, '%')
    sh_commands = template.result(binding)
    sh_file = "#{directory}/integrity.sh"
    File.open(sh_file, 'w'){|f| f.write(sh_commands) }
  end

  def run(image, &block)
    cmd = case image
      when :mysql
        uuid = "mysql-#{timestamp}"
        running[:mysql] = uuid
        Commands.docker_run_mysql(uuid)
      when :image
        running[:image] = token
        mysql = running[:mysql].presence || 'mysql'
        Commands.docker_run_image(mysql, token)
      else
        running[image]  = token
        Commands.docker_run(image, token)
      end

    run_in_dir(cmd, &block)
  end

  def build!
    make_tmp_dir!
    get_build_script_template!
    process_erb!
    create_docker_file!
    cmd = Commands.docker_build(token)
    run_in_dir!(cmd)
  end

  def github_token
    Integrity.config.github_token
  end

  def github_account
    Integrity.config.github_account
  end

  def create_docker_file!
    fetch_file! 'Dockerfile'
  end
end
