require File.dirname(__FILE__) + "/lib/integrity"
require "rake/testtask"
require "rcov/rcovtask"

desc "Run all tests and check test coverage"
task :default => "test:coverage:verify"

desc "Run tests"
task :test => %w(test:units test:acceptance)

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  Rake::TestTask.new(:acceptance) do |t|
    t.test_files = FileList["test/acceptance/*_test.rb"]
  end

  desc "Measure test coverage"
  task :coverage => %w(test:coverage:units test:coverage:acceptance)

  namespace :coverage do
    desc "Measure test coverage of unit tests"
    Rcov::RcovTask.new(:units) do |rcov|
      rcov.pattern   = "test/unit/*_test.rb"
      rcov.rcov_opts = %w(--html --aggregate .aggregated_coverage_report)
      rcov.rcov_opts << ENV["RCOV_OPTS"] if ENV["RCOV_OPTS"]
    end

    desc "Measure test coverage of acceptance tests"
    Rcov::RcovTask.new(:acceptance) do |rcov|
      rcov.pattern   = "test/acceptance/*_test.rb"
      rcov.rcov_opts = %w(--html --aggregate .aggregated_coverage_report)
      rcov.rcov_opts << ENV["RCOV_OPTS"] if ENV["RCOV_OPTS"]
    end

    desc "Verify test coverage"
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

  desc "Install all gems on which the tests depend on"
  task :install_dependencies do
    system 'gem install redgreen rr mocha ruby-debug dm-sweatshop webrat ZenTest'
    system 'gem install -s http://gems.github.com jeremymcanally-context jeremymcanally-matchy jeremymcanally-pending foca-storyteller'
  end
end

desc "Launch Integrity real quick"
task :launch do
  ruby "bin/integrity launch"
end

begin
  require "jeweler"

  namespace :jeweler do
    Jeweler::Tasks.new do |s|
      files  = `git ls-files`.split("\n").reject {|f| f =~ %r(^test/acceptance) || f =~ %r(^test/unit) || f =~ /^\.git/ }

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

      s.add_dependency 'sinatra', ['>= 0.9.0.3']
      s.add_dependency 'haml',    ['>= 2.0.0']
      s.add_dependency 'data_mapper', ['>= 0.9.10']
      s.add_dependency 'uuidtools'   # required by dm-types
      s.add_dependency 'bcrypt-ruby' # required by dm-types
      s.add_dependency 'json'
      s.add_dependency 'foca-sinatra-ditties', ['>= 0.0.3']
      s.add_dependency 'thor'
    end
  end
rescue LoadError
end
