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

# Add something like the following (replacing the /path/to/ section in each of
# the paths with appropriate values for your system) to your crontab to
# automatically build any oustanding commits of your projects every few
# minutes.
#
# */2 * * * * cd /path/to/integrity && /path/to/ruby ./bin/rake build_new_commits >> /path/to/cron.log 2>$
desc "Will build the latest commit for any project that has already been built and the latest commit has not already been built"
task :build_new_commits do
  require "init"
  Integrity.log("Checking for new commits at #{Time.now}")
  Integrity::Project.all.each do |project|
    # Don't build if project is just being set up, or a build of 'HEAD' is already outstanding or the latest commit has already
    # been built.
    unless project.blank? ||
        project.last_build.commit.identifier == 'HEAD' ||
        (head = Integrity::Repository.new(project.uri, project.branch, 'HEAD').head) == project.last_build.commit.identifier
      project.build(head)
    end
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
