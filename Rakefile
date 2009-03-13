require "rake/testtask"
require "rake/clean"
require "rcov/rcovtask"

begin
  require "metric_fu"
rescue LoadError
end

module Integrity
  def self.version
    YAML.load_file("VERSION.yml").values.join(".")
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

  desc "Install all gems on which the tests depend on"
  task :install_dependencies do
    system "gem install rr mocha dm-sweatshop ZenTest"
    system "gem install -s http://gems.github.com jeremymcanally-context \
jeremymcanally-matchy jeremymcanally-pending foca-storyteller"
    system "git submodule update --init"
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
      s.name                 = "integrity"
      s.summary              = "The easy and fun Continuous Integration server"
      s.description          = "Your Friendly Continuous Integration server. Easy, fun and painless!"
      s.homepage             = "http://integrityapp.com"
      s.rubyforge_project    = "integrity"
      s.email                = "contacto@nicolassanguinetti.info"
      s.authors              = ["Nicolás Sanguinetti", "Simon Rozet"]
      s.files                = FileList["[A-Z]*", "{bin,lib,test,vendor}/**/*"]
      s.executables          = ["integrity"]
      s.post_install_message = "Run `integrity help` for information on how to setup Integrity."

      s.add_dependency "sinatra", [">= 0.9.1.1"]
      s.add_dependency "haml",    [">= 2.0.0"]
      s.add_dependency "data_mapper", [">= 0.9.10"]
      s.add_dependency "uuidtools"   # required by dm-types
      s.add_dependency "bcrypt-ruby" # required by dm-types
      s.add_dependency "json"
      s.add_dependency "foca-sinatra-ditties", [">= 0.0.3"]
      s.add_dependency "thor"
    end
  end
rescue LoadError
end
