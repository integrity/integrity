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
  DataMapper.auto_upgrade!
end

namespace :utils do
  desc "Clear old builds" 
  task :remove_old_builds, :num_builds_to_keep do |t, args|
    num = (args.num_builds_to_keep || 50).to_i
    num = (num <= 0) ? 1 : num # Don't accidentally the whole build table
    puts "Purging builds older than the most recent #{num} builds."
    require "init"
    require "lib/integrity/build"
    builds = Integrity::Build.all(:completed_at.not => nil, :order => [ :completed_at.desc, :id.desc ], :offset => num, :limit => 9_999)
    builds.map{|b| b.destroy }
  end
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

begin
  namespace :resque do
    require "resque/tasks"

    desc "Start a Resque worker for Integrity"
    task :work do
      require "init"
      ENV["QUEUE"] = "integrity"
      Rake::Task["resque:resque:work"].invoke
    end
  end
rescue LoadError
end

desc "Generate HTML documentation."
file "doc/integrity.html" => ["doc/htmlize",
  "doc/integrity.txt",
  "doc/integrity.css"] do |f|
  sh "cat doc/integrity.txt | doc/htmlize > #{f.name}"
end

CLOBBER.include("doc/integrity.html")
