require File.dirname(__FILE__) + "/lib/integrity"
require "rake/testtask"
require "rcov/rcovtask"
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

desc "Run all tests and check test coverage"
task :default => "test:coverage:verify"

Rake::TestTask.new do |t|
  t.test_files = FileList["test/*_test.rb"]
end

namespace :test do
  desc "Measure test coverage"
  Rcov::RcovTask.new(:coverage) do |rcov|
    rcov.pattern   = "test/**/*_test.rb"
    rcov.rcov_opts = %w(--html)
  end
  
  namespace :coverage do
    desc "Verify coverage is at 100%"
    task :verify => "test:coverage" do
      File.read("coverage/index.html") =~ /<tt class='coverage_total'>\s*(\d+\.\d+)%\s*<\/tt>/
      coverage = $1.to_f
      
      puts
      if coverage == 100
        puts "\e[32m100% coverage! Awesome!\e[0m"
      else
        puts "\e[31mOnly #{coverage}% code coverage. You can do better ;)\e[0m"
      end
    end
  end
end

Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ["--color", "--format", "progress"]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
  t.libs = ['lib']
  t.rcov = false
end

namespace :spec do
  Spec::Rake::SpecTask.new(:coverage) do |t|
    t.spec_opts = ["--color", "--format", "progress"]
    t.spec_files = Dir['spec/**/*_spec.rb'].sort
    t.libs = ['lib']
    t.rcov = true
    t.rcov_opts = ['--exclude-only', '".*"', '--include-file', '^lib']
  end

  namespace :coverage do
    RCov::VerifyTask.new(:verify) do |t|
      t.threshold = 100
      t.index_html = "coverage" / 'index.html'
    end
  end
end

namespace :db do
  desc "Setup connection."
  task :connect do
    config = File.expand_path(ENV['CONFIG']) if ENV['CONFIG']
    config = Integrity.root / 'config.yml' if File.exists?(Integrity.root / 'config.yml')
    Integrity.new(config)
  end

  desc "Automigrate the database"
  task :migrate => :connect do
    require "project"
    require "build"
    require "notifier"
    DataMapper.auto_migrate!
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    files  = `git ls-files`.split("\n").reject {|f| f =~ %r(^spec) || f =~ %r(^vendor/rspec) || f =~ /^\.git/ } 
    files += %w(spec/spec_helper.rb spec/form_field_matchers.rb)

    s.name                 = 'integrity'
    s.summary              = 'The easy and fun Continuous Integration server'
    s.description          = 'Your Friendly Continuous Integration server. Easy, fun and painless!'
    s.homepage             = 'http://integrityapp.com'
    s.rubyforge_project    = 'integrity'
    s.email                = 'contacto@nicolassanguinetti.info'
    s.authors              = ['Nicolás Sanguinetti', 'Simon Rozet']
    s.files                = files
    s.executables          = ['integrity']
    s.post_install_message = 'Run `integrity help` for information on how to setup Integrity.'

    s.add_dependency 'sinatra', ['>= 0.3.2']
    s.add_dependency 'haml' # ah, you evil monkey you
    s.add_dependency 'dm-core', ['>= 0.9.5']
    s.add_dependency 'dm-validations', ['>= 0.9.5']
    s.add_dependency 'dm-types', ['>= 0.9.5']
    s.add_dependency 'dm-timestamps', ['>= 0.9.5']
    s.add_dependency 'dm-aggregates', ['>= 0.9.5']
    s.add_dependency 'data_objects', ['>= 0.9.5']
    s.add_dependency 'do_sqlite3', ['>= 0.9.5']        
    s.add_dependency 'json'
    s.add_dependency 'foca-sinatra-diddies', ['>= 0.0.2']
    s.add_dependency 'rspec_hpricot_matchers'
    s.add_dependency 'thor'
    s.add_dependency 'bcrypt-ruby'
  end
rescue LoadError
end

