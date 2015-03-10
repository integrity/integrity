require 'fileutils'

module Integrity
  class Jemima

    STATIC_PREFIX = 'jemima'
    TEMPLATES_DIR = 'services/templates/server'

    attr_reader :stack_id, :build_id,
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
      @stack_id      = format("%s_%s", FIXED_PREFIX, @build_id)
    end

    def out_dir
      File.join('/tmp', @stack_id)
    end

    def rendered_files
      Dir["#{out_dir}/*.service"].map do |file|
        File.open(file, 'r')
      end
    end

    def bake_erb
      #stack_id = ARGV[0]
      #jarvis_branch = ARGV[1]
      #jarvis_sha = ARGV[2]
      #frick_branch = ARGV[3]
      #frick_sha = ARGV[4]
      #tim_branch = ARGV[5]
      #tim_sha = ARGV[6]
      github_read_token = ENV['GITHUB_READ_TOKEN']
      aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
      aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      aws_secret_key = ENV['AWS_SECRET_KEY']

      #puts <<-HERE
      #stack_id      = #{stack_id}
      #jarvis_branch = #{jarvis_branch}
      #jarvis_sha    = #{jarvis_sha}
      #frick_branch  = #{frick_branch}
      #frick_sha     = #{frick_sha}
      #tim_branch    = #{tim_branch}
      #tim_sha       = #{tim_sha}
      #github_read_token     = #{github_read_token}
      #aws_access_key_id     = #{aws_access_key_id}
      #aws_secret_access_key = #{aws_secret_access_key}
      #aws_secret_key        = #{aws_secret_key}
      #HERE

      b = binding

      mk_out_dir

      Dir[TEMPLATES_DIR + '/*.erb'].each do |erb_fname|
        contents = ERB.new(File.read(erb_fname)).result(b)
        outf = baked_filename(erb_fname)

        File.open(outf, 'w') do |f|
          f.puts contents
        end
      end
    end

    private

    def mk_out_dir
      FileUtils.mkdir_p out_dir
    end

    def erbless_filename(fname)
      fname.sub(/\.erb$/, '')
    end

    def baked_filename(fname)
      File.join(out_dir, "#{@stack_id}_#{File.basename fname}")
    end
  end
end

j = Integrity::Jemima.new {
    build_id: 123456
    frick:  { branch: 'dockyard', sha: '' },
    jarvis: { branch: 'dockyard', sha: '' },
    tim:    { branch: 'dockyard', sha: '' },
  }
