require "rake/testtask"

def spec
  @spec ||= begin
    require "rubygems/specification"
    eval(File.read("integrity.gemspec"))
  end
end

desc "Default: run all tests"
task :default => :test

desc "Launch Integrity real quick"
task :launch do
  ruby "bin/integrity launch"
end

desc "Run tests"
task :test => %w(test:units test:acceptance)
namespace :test do
  desc "Run unit tests"
  Rake::TestTask.new(:units) do |t|
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  desc "Run acceptance tests"
  Rake::TestTask.new(:acceptance) do |t|
    t.test_files = FileList["test/acceptance/*_test.rb"]
  end
end

desc "Special task for running tests on <http://builder.integrityapp.com>"
task :ci do
  require "metric_fu"

  Rake::Task["test"].invoke

  metrics = %w(flay flog:all reek roodi saikuro)
  metrics.each { |m| Rake::Task["metrics:#{m}"].invoke }

  rm_rf "/var/www/integrity-metrics"
  mv "tmp/metric_fu", "/var/www/integrity-metrics"

  File.open("/var/www/integrity-metrics/index.html", "w") { |f|
    f.puts "<ul>"
    metrics.map { |m| m.split(":").first }.each { |m|
      f.puts %Q(<li><a href="/#{m}">#{m}</a></li>)
    }
    f.puts "</ul>"
  }
end

begin
  require "mg"
  MG.new("integrity.gemspec")
rescue LoadError
end

