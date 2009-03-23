require "rake/testtask"
require "rake/clean"

begin
  require "metric_fu"
rescue LoadError
end

def spec
  @spec ||= begin
    require "rubygems/specification"
    eval(File.read("integrity.gemspec"))
  end
end

desc "Default: run all tests"
task :default => :test

desc "Special task for running tests on <http://builder.integrityapp.com>"
task :ci do
  sh "git submodule update --init"

  Rake::Task["test"].invoke

  metrics = %w(flay flog:all reek roodi saikuro)
  metrics.each { |m| Rake::Task["metrics:#{m}"].invoke }

  rm_rf "/var/www/integrity-metrics"
  mv "tmp/metric_fu", "/var/www/integrity-metrics"

  File.open("/var/www/integrity-metrics/index.html", "w") { |f|
    f << "<ul>"
    metrics.map { |m| m.split(":").first }.each { |m|
      f << %Q(<li><a href="/#{m}">#{m}</a></li>)
    }
    f << "</ul>"
  }
end

desc "Run tests"
task :test => %w(test:units test:acceptance)
namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  Rake::TestTask.new(:acceptance) do |t|
    t.test_files = FileList["test/acceptance/*_test.rb"]
  end

  desc "Install tests dependencies"
  task :install_dependencies do
    puts "NOTE: assuming you have gems.github.com in your gem sources"

    system "gem install " +
      spec.dependencies.select { |dep| dep.type  == :development }.
        collect(&:name).join(" ")
  end
end

desc "Install Integrity dependencies"
task :install_dependencies do
  puts "NOTE: assuming you have gems.github.com in your gem sources"

  system "gem install " +
    spec.dependencies.select { |dep| dep.type == :runtime }.
      collect(&:name).join(" ")
end

desc "Launch Integrity real quick"
task :launch do
  ruby "bin/integrity launch"
end

begin
  require "mg"

  MG.new("integrity.gemspec")
rescue LoadError
end
