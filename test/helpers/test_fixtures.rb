require 'rubygems'
require 'dm-sweatshop'

include DataMapper::Sweatshop::Unique

class Array
  def pick
    self[rand(self.length)]
  end
end

def commit_metadata
  meta_data = <<-EOS
---
:author: #{/\w+ \w+ <\w+@example.org>/.gen}
:message: >-
  #{/\w+/.gen}
:date: #{Time.mktime(2008, 12, 15, 18)}
EOS
end

def notifier_config
  {}.tap do |config|
    5.times { config[/\w+/.gen] = /\w+/.gen }
  end
end


Integrity::Project.fixture do
  { :name       => (name = unique { /\w+/.gen }),
    :uri        => "git://github.com/#{/\w+/.gen}/#{name}.git",
    :branch     => ["master", "test-refactoring", "lh-34"].pick,
    :command    => ["rake", "make", "ant -buildfile test.xml"].pick,
    :public     => [true, false].pick,
    :building   => [true, false].pick }
end

Integrity::Project.fixture(:integrity) do
  { :name       => "Integrity",
    :uri        => "git://github.com/foca/integrity.git",
    :branch     => "master",
    :command    => "rake",
    :public     => true,
    :building   => false }
end

Integrity::Build.fixture do
  { :output     => /[:paragraph:]/.gen,
    :successful => true,
    :created_at => unique {|i| Time.mktime(2008, 12, 15, 18, (59 - i) % 60) },
    :commit_identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
    :commit_metadata   => commit_metadata }
end

Integrity::Notifier.fixture(:irc) do
  class Integrity::Notifier::IRC < Integrity::Notifier::Base
    def self.to_haml; ""; end
    def deliver!; nil; end
  end

  { :name => "IRC", :config => notifier_config }
end
