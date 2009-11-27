module IntegrityTest
  class AbstractRepo
    def initialize(name = "test_repo")
      @path = Integrity.config.directory.join(name)
    end

    def create
      add_commit("First commit") {
        `echo 'just a test repo' >> README`
        add "README"
      }
    end

    def add_commit(message)
      Dir.chdir(@path) {
        yield
        commit(message)
      }
    end

    def add_successful_commit
      add_commit("This commit will work") {
        `echo '#{script(0)}' > test`
        `chmod +x test`
        add "test"
      }
    end

    def add_failing_commit
      add_commit("This commit will fail") {
        system "echo '#{script(1)}' > test"
        system "chmod +x test"
        add    "test"
      }
    end

    def head
      commits.last["id"]
    end

    def short_head
      head[0..6]
    end

    def command
      "./test"
    end

    def script(status)
      <<SH
  #!/bin/sh
  echo "Running tests..."
  exit #{status}
SH
    end
  end

  class GitRepo < AbstractRepo
    def scm
      "git"
    end

    def branch
      "master"
    end

    def uri
      @path
    end

    def add(file)
      `git add #{file}`
    end

    def commit(message)
      `git commit -m "#{message}"`
    end

    def head
      Dir.chdir(@path) { `git log --pretty=format:%H | head -1`.chomp }
    end

    def create
      FileUtils.mkdir(@path)

      Dir.chdir(@path) {
        `git init`
        `git config user.name 'John Doe'`
        `git config user.email 'johndoe@example.org'`
      }

      super
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
  end

  class SvnRepo < AbstractRepo
    def initialize(name = "test_repo")
      super

      server = @path.join("..", "svn-server")
      server.mkdir
      @remote = server.join(@path.basename)
    end

    def uri
      "file://#{@remote}"
    end

    def branch
      ""
    end

    def scm
      "svn"
    end

    def commit(msg)
      `svn commit -m "#{msg}"`
      `svn up`
    end

    def add(file)
      `svn add #{file}`
    end

    def create
      `svnadmin create #{@remote}`

      @remote.join("conf", "svnserve.conf").open("w") { |f|
        f.puts "[general]"
        f.puts "anon-access = write"
        f.puts "auth-access = write"
      }

      `svn checkout file://#{@remote} #{@path}`

      super
    end

    # TODO get rid of the Hpricot dependency
    def commits
      Dir.chdir(@path) do
        doc = Hpricot::XML(`svn log --xml`)
        (doc/:log/:logentry).inject([]) { |acc, c|
          acc << { "id" => c["revision"],
            "message"   => c.at("msg").inner_html,
            "timestamp" => Time.parse(c.at("date").inner_html) }
        }.reverse
      end
    end
  end
end
