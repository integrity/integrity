class Docker
  include Runnable

  attr_reader :token, :running

  def initialize(directory, logger)
    super
    @token   = Integrity.generate_sha1
    @running = {}
  end

  def make_tmp_dir!
    logger.debug "Making tmp directory: #{directory}"
    runner.run! "mkdir -p #{directory}"
  end

  def fetch_file!(file)
    logger.debug "Fetching file from github: #{file}"
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
    logger.debug "Processing build template..."
    sh_file = "#{directory}/integrity.sh"
    sh_commands = ERB.new(File.read("#{directory}/.integrity.erb")).result(binding)
    logger.debug "Creating build script: #{sh_file}\n----------------\n#{sh_commands}\n----------------"
    # File.open(sh_file, 'w'){|f| f.write(sh_commands) }
    File.new(sh_file, 'w').write(sh_commands)
  end

  def run(image, &block)
    cmd = case image
      when :mysql
        uuid = "mysql-#{Integrity.timestamp}"
        running[:mysql] = uuid
        logger.debug "Running mysql: #{uuid}"
        Commands.docker_run_mysql(uuid)
      when :image
        running[:image] = token
        mysql = running[:mysql].presence || 'mysql'
        logger.debug "Running image: #{token}"
        Commands.docker_run_image(mysql, token)
      else
        running[image]  = token
        logger.debug "Running image: #{token}"
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
