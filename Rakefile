require File.dirname(__FILE__) + "/lib/integrity"
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

task :default => ["spec:coverage", "spec:coverage:verify"]

# shared options between the spec and the spec:coverage tasks
shared_spec_opts = lambda do |t|
  t.spec_opts = ["--color", "--format", "specdoc"]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
  t.libs = ['lib']
end

Spec::Rake::SpecTask.new(:spec) do |t|
  shared_spec_opts[t]
  t.rcov = false
end

namespace :spec do
  Spec::Rake::SpecTask.new(:coverage) do |t|
    shared_spec_opts[t]
    t.rcov = true
    t.rcov_opts = ['--exclude-only', '".*"', '--include-file', '^lib']
  end

  namespace :coverage do
    RCov::VerifyTask.new(:verify) do |t|
      t.threshold = 100
      t.index_html = "coverage" / 'index.html'
    end
  end
end

namespace :db do
  desc "Setup connection."
  task :connect do
    ENV['CONFIG'] ? Integrity.new(ENV['CONFIG']) : Integrity.new
  end

  desc "Automigrate the database"
  task :migrate => :connect do
    require "project"
    require "build"
    DataMapper.auto_migrate!
  end
end
