require "rake/testtask"
require "rake/clean"
require "rcov/rcovtask"

begin
  require "metric_fu"
rescue LoadError
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

directory "dist/"
CLOBBER.include("dist")

# Load the gemspec using the same limitations as github
def spec
  @spec ||=
    begin
      require "rubygems/specification"
      data = File.read("integrity.gemspec")
      spec = nil
      Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
      spec
    end
end

def package(ext="")
  "dist/integrity-#{spec.version}" + ext
end

desc "Build and install as local gem"
task :install => package('.gem') do
  sh "gem install #{package('.gem')}"
end

desc "Publish the current release on Rubyforge"
task :rubyforge => ["rubyforge:gem", "rubyforge:tarball", "rubyforge:git"]

namespace :rubyforge do
  desc "Publish gem and tarball to rubyforge"
  task :gem => package(".gem") do
    sh "rubyforge add_release integrity integrity #{spec.version} #{package('.gem')}"
  end

  task :tarball => package(".tar.gz") do
    sh "rubyforge add_file integrity integrity #{spec.version} #{package('.tar.gz')}"
  end

  desc "Push to gitosis@rubyforge.org:integrity.git"
  task :git do
    sh "git push gitosis@rubyforge.org:integrity.git master"
  end
end

desc "Build gem tarball into dist/"
task :package => %w(.gem .tar.gz).map { |ext| package(ext) }
namespace :package do
  file package(".tar.gz") => "dist/" do |f|
    sh <<-SH
      git archive \
        --prefix=integrity-#{spec.version}/ \
        --format=tar \
        HEAD | gzip > #{f.name}
    SH
  end

  file package(".gem") => "dist/" do |f|
    sh "gem build integrity.gemspec"
    mv File.basename(f.name), f.name
  end
end
