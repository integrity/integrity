module TestHelper
  class GitRepo
    attr_reader :path, :branch

    alias_method :uri, :path

    def initialize(name = "test_repo", branch = "master")
      @path   = Integrity.directory.join(name)
      @branch = branch
    end

    def create
      FileUtils.mkdir(@path)

      Dir.chdir(@path) {
        `git init`
        `git config user.name 'John Doe'`
        `git config user.email 'johndoe@example.org'`
      }

      add_commit("First commit") {
        `echo 'just a test repo' >> README`
        `git add README`
      }
    end

    def add_successful_commit
      add_commit("This commit will work") {
        `echo '#{script(0)}' > test`
        `chmod +x test`
        `git add test`
      }
    end

    def add_failing_commit
      add_commit("This commit will fail") {
        `echo '#{script(1)}' > test`
        `chmod +x test`
        `git add test`
      }
    end

    def head
      Dir.chdir(@path) { `git log --pretty=format:%H | head -1`.chomp }
    end

    def short_head
      head[0..6]
    end

    def commits
      Dir.chdir(@path) {
        `git log --pretty=oneline`.collect { |l| l.split(" ").first }.
        inject([]) { |acc, sha1|
          fmt  = "---%nmessage: >-%n  %s%ntimestamp: %ci%n" \
            "id: %H%nauthor: %n name: %an%n email: %ae%n"
          acc << YAML.load(`git show -s --pretty=format:"#{fmt}" #{sha1}`)
        }.reverse
      }
    end

    def add_commit(message)
      Dir.chdir(@path) {
        yield
        `git commit -m "#{@branch}: #{message}"`
      }
    end

    def checkout(branch)
      @branch = branch
      Dir.chdir(@path) { `git checkout -b #{branch} > /dev/null 2>&1` }
    end

    def script(status)
      <<SH
  #!/bin/sh
  echo "Running tests..."
  exit #{status}
SH
    end
  end
end
