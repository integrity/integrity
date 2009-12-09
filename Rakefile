require "rake/testtask"
require "rake/clean"

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

task :db do
  require "init"
  DataMapper.auto_migrate!
end

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear do
    require "init"
    require "integrity/builder/delayed"
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker."
  task :work do
    require "init"
    require "integrity/builder/delayed"
    Delayed::Worker.new.start
  end
end

desc "Generate HTML documentation."
file "doc/integrity.html" => ["doc/htmlize",
  "doc/integrity.txt",
  "doc/integrity.css"] do |f|
  sh "cat doc/integrity.txt | doc/htmlize > #{f.name}"
end

CLOBBER.include("doc/integrity.html")
