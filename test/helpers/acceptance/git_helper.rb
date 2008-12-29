module GitHelper
  @@_git_repositories = Hash.new {|h,k| h[k] = Repo.new(k) }
  
  def git_repo(name)
    @@_git_repositories[name]
  end
  
  def destroy_all_git_repos
    @@_git_repositories.each {|n,r| r.destroy }
  end
  
  class Repo
    attr_reader :path
    
    def initialize(name)
      @name = name
      @path = "/tmp" / @name.to_s
      create
    end
    
    def path
      @path / ".git"
    end
    
    def create
      destroy
      FileUtils.mkdir_p @path
      
      Dir.chdir(@path) do
        system 'git init &>/dev/null'
        system 'git config user.name "John Doe"'
        system 'git config user.email "johndoe@example.org"'
        system 'echo "just a test repo" >> README'
        system 'git add README &>/dev/null'
        system 'git commit -m "First commit" &>/dev/null'
      end
      
      add_successful_commit
    end
    
    def add_failing_commit
      Dir.chdir(@path) do
        system %Q(echo '#{build_script(false)}' > test)
        system %Q(chmod +x test)
        system %Q(git add test &>/dev/null)
        system %Q(git commit -m "This commit will fail" &>/dev/null)
      end
    end

    def add_successful_commit
      Dir.chdir(@path) do
        system %Q(echo '#{build_script(true)}' > test)
        system %Q(chmod +x test)
        system %Q(git add test &>/dev/null)
        system %Q(git commit -m "This commit will work" &>/dev/null)
      end
    end
    
    def head
      Dir.chdir(@path) do
        `git log --pretty=format:%H | head -1`.chomp[0..6]
      end
    end
    
    def destroy
      FileUtils.rm_rf @path if File.directory?(@path)
    end
    
    protected
    
      def build_script(successful=true)
        <<-script
!/bin/sh
echo "Running tests..."
exit #{successful ? 0 : 1}
script
      end
  end
end