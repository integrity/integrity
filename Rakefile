require "rake/testtask"
require "rake/clean"
require "rcov/rcovtask"

begin
  require "metric_fu"
rescue LoadError
end

require File.dirname(__FILE__) + "/lib/integrity"

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

directory "dist/"
CLOBBER.include("dist")

def package(ext="")
  "dist/integrity-#{Integrity.version}" + ext
end

def ask_confirmation
  puts <<-EOF
You're about to publish a new release on Rubyforge.

Doubled-checked that:
  * You have regenerated the gemspec
  * Bumped the version (current is #{Integrity.version})
  * Updated the ChangeLog

Answer "yes" to continue.
EOF

  $stdin.gets
  abort("Release aborted") unless $_.chomp == "yes"
end

desc "Publish the current release on Rubyforge"
task :rubyforge => ["rubyforge:gem", "rubyforge:tarball", "rubyforge:git"]

namespace :rubyforge do
  desc "Publish gem and tarball to rubyforge"
  task :gem => package(".gem") do
    ask_confirmation

    sh "rubyforge add_release integrity integrity #{Integrity.version} #{package('.gem')}"
  end

  task :tarball => package(".tar.gz") do
    ask_confirmation

    sh "rubyforge add_file integrity integrity #{Integrity.version} #{package('.tar.gz')}"
  end

  desc "Push to gitosis@rubyforge.org:integrity.git"
  task :git do
    ask_confirmation

    sh "git push gitosis@rubyforge.org:integrity.git master"
  end
end

desc "Build gem tarball into dist/"
task :package => %w(.gem .tar.gz).map { |ext| package(ext) }
namespace :package do
  file package(".tar.gz") => "dist/" do |f|
    sh <<-SH
      git archive \
        --prefix=integrity-#{Integrity.version}/ \
        --format=tar \
        HEAD | gzip > #{f.name}
    SH
  end

  file package(".gem") => %w[dist/ jeweler:gemspec:validate] do |f|
    sh "gem build integrity.gemspec"
    mv File.basename(f.name), f.name
  end
end

begin
  require "jeweler"

  namespace :jeweler do
    Jeweler::Tasks.new do |s|
      files  = `git ls-files`.split("\n").reject { |f|
          f =~ %r(^test/acceptance) ||
          f =~ %r(^test/unit)       ||
          f =~ /^\.git/
      }

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
