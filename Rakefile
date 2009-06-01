require "rake/testtask"

desc "Default: run all tests"
task :default => :test

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

begin
  require "metric_fu"

  task :metrics do
    metrics = [:churn, :flog, :flay, :reek, :roodi]
    MetricFu::Configuration.run { |c| c.metrics = metrics }

    Rake::Task["metrics:all"].invoke
  end

  desc "Special task for running tests on <http://builder.integrityapp.com>"
  task :ci => [:test, :metrics] do
    rm_rf "/var/www/integrity-metrics"
    mv "tmp/metric_fu", "/var/www/integrity-metrics"

    File.open("/var/www/integrity-metrics/index.html", "w") { |f|
      f.puts "<ul>"
      MetricFu.configuration.metrics.map { |m| m.to_s.split(":").first }.each { |m|
        f.puts %Q(<li><a href="/#{m}">#{m}</a></li>)
      }
      f.puts "</ul>"
    }
  end
rescue LoadError
  raise
end

begin
  require "mg"
  MG.new("integrity.gemspec")
rescue LoadError
end

