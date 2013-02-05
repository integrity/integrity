# coding: utf-8

module TestHelper
  class GitRepo
    attr_reader :path, :branch

    alias_method :uri, :path

    def initialize(name = "test_repo", branch = "master")
      @path   = Integrity.config.directory.join(name)
      @branch = branch
    end

    def create
      FileUtils.mkdir(@path)

      Dir.chdir(@path) {
        run!("git init")
        run!("git config user.name 'John Doe'")
        run!("git config user.email 'johndoe@example.org'")
      }

      add_commit("First commit") {
        run!("echo 'just a test repo' >> README")
        run!("git add README")
      }
    end

    def add_successful_commit
      add_commit("This commit will work") {
        run!("echo '#{script(0)}' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end

    def add_failing_commit
      add_commit("This commit will fail") {
        run!("echo '#{script(1)}' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end
    
    def add_commit_with_very_long_commit_message_lines
      # 2000 chars
      subject = '123456789 ' * 200
      message = "#{subject} end-subject\n\nAnd again in body:\n\n#{subject} end-body"
      add_commit(message) {
        run!("echo '#{script(0)}' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end
    
    def add_commit_with_utf8_subject_and_body
      subject = 'Коммит'
      message = "#{subject} end-subject\n\nAnd again in body:\n\n#{subject} end-body"
      add_commit(message) {
        run!("echo '#{script(0)}' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end

    def add_commit_with_utf8_command_output
      add_commit("This commit will work") {
        run!("echo '#{utf8_script(0)}' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end

    def add_commit_with_invalid_utf8_command_output
      add_commit("This commit will work") {
        run!("echo '#{invalid_utf8_script(0)}' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end

    def add_commit_echoing_integrity_branch
      add_commit("This commit echoes INTEGRITY_BRANCH") {
        run!("echo 'echo branch=$INTEGRITY_BRANCH' > test")
        run!("chmod +x test")
        run!("git add test")
      }
    end

    def head
      Dir.chdir(@path) { run!("git log --pretty=format:%H | head -1").chomp }
    end

    def short_head
      head[0..6]
    end

    def commits
      Dir.chdir(@path) {
        run!("git log --pretty=format:%H").each_line.collect{|l| l.split("\n").first}.
        inject([]) { |acc, sha1|
          # Note: psych will return unquoted timestamp as a Time object,
          # syck will return it as a string
          # Note: use single quotes because of how we invoke git below
          fmt  = "---%nmessage: >-%n  %s%ntimestamp: '%ci'%n" \
            "id: %H%nauthor: %n name: %an%n email: %ae%n"
          acc << YAML.load(run!(%(git show -s --pretty=format:"#{fmt}" #{sha1})))
        }.reverse
      }
    end

    def add_commit(message)
      Dir.chdir(@path) {
        yield
        run!(%(git commit -m "#{@branch}: #{message}" \
           --author="John Doe <jdoe@gmail.com>"))
      }
    end

    def checkout(branch)
      @branch = branch
      Dir.chdir(@path) { run!("git checkout -b #{branch} > /dev/null 2>&1") }
    end

    def script(status)
      <<SH
  #!/bin/sh
  echo "Running tests..."
  exit #{status}
SH
    end

    def utf8_script(status)
      <<SH
  #!/bin/sh
  echo "Тесты выполняются..."
  exit #{status}
SH
    end

    def invalid_utf8_script(status)
      <<SH
  #!/bin/sh
  echo "Bogus \250 UTF-8..."
  exit #{status}
SH
    end
    
    class CommandFailed < StandardError
    end
    
    def run!(command)
      output = `#{command}`
      if $? != 0
        msg = "Command #{command} failed with code #{$?}"
        unless output.empty?
          msg += "\n#{output}"
        end
        raise CommandFailed.new(msg)
      end
      output
    end
  end
end
