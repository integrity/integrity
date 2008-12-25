require "webrat/sinatra"
require Integrity.root / "app"

module AcceptanceHelper
  include FileUtils

  def export_directory
    Integrity.root / "exports"
  end

  def git_repository_directory
    Integrity.root / "my-test-project.git"
  end

  def enable_auth!
    Integrity.config[:use_basic_auth]      = true
    Integrity.config[:admin_username]      = "admin"
    Integrity.config[:admin_password]      = "test"
    Integrity.config[:hash_admin_password] = false
  end
  
  def disable_auth!
    Integrity.config[:use_basic_auth] = false
  end

  def create_git_repository!
    rm_r  git_repository_directory if File.directory?(git_repository_directory)
    mkdir git_repository_directory

    Dir.chdir(git_repository_directory) do
      `git init`
      File.open("test.rb", "w") do |f|
        f.puts "require 'test/unit/assertions'"
        f.puts "include Test::Unit::Assertions"
        f.puts "puts %q{this is just because Build#output can't be blank now ATM}"
        f.puts "assert_equal 'foo', 'foo'"
      end
      `git add test.rb`
      `git commit -m "initial import"`
      File.open("README", "w") { |f| f << "uh?" }
      `git add README`
      `git commit -m "readme"`
    end
  end

  def set_and_create_export_directory!
    rm_r(export_directory) if File.directory?(export_directory)
    mkdir(export_directory)
    Integrity.config[:export_directory] = export_directory
  end

  def setup_log!
    pathname = Integrity.root / "integrity.log"
    rm pathname if File.exists?(pathname)
    Integrity.config[:log] = pathname
  end
  
  def response
    @response
  end
end

module PrettyStoryPrintingHelper
  def self.included(base)
    base.before(:all) do
      puts
      print "\e[36m"
      puts  self.class.story.to_s.gsub(/^\s+/, '')
      print "\e[0m"
    end

    base.after(:all) do
      puts
    end    
    
    base.extend ClassMethods
  end
  
  module ClassMethods
    def story(story=nil)
      @story = story if story
      @story
    end  
  end
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  class << self
    alias :scenario :test
  end

  include AcceptanceHelper
  include PrettyStoryPrintingHelper
end
