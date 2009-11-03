require "rake/testtask"

desc "Default: run all tests"
task :default => :test

desc "Run tests"
task :test => %w[test:unit test:acceptance]
namespace :test do
  desc "Run unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  desc "Run acceptance tests"
  Rake::TestTask.new(:acceptance) do |t|
    t.libs << "test"
    t.test_files = FileList["test/acceptance/*_test.rb"]
  end
end

desc "Generate documentation using asciidoc"
task :doc do
  sh "asciidoc -a stylesdir=#{File.dirname(__FILE__)}/doc/stylesheets \
    -a theme=bare doc/integrity.txt"
end

task :db do
  require "init"
  DataMapper.auto_migrate!
end

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear do
    require "init"
    require "integrity/dj"
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker."
  task :work do
    require "init"
    require "integrity/dj"
    Delayed::Worker.new.start
  end
end

begin
  require "mg"
  MG.new("integrity.gemspec")
rescue LoadError
end

