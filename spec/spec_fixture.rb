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
:date: #{Time.now}
EOS
end

def notifier_config
  {}.tap do |config|
    5.times { config[/\w+/.gen] = /\w+/.gen }
  end
end

Integrity::Project.fixture do
  { :name       => (name = unique { /\w+/.gen }),
    :uri        => "git://github.com/#{/\w+/.gen}/integrity.git",
    :branch     => %w[master bug_4567 build-in-badground].pick,
    :command    => "rake master",
    :public     => true,
    :building   => false }
end

Integrity::Build.fixture do
  { :output     => /[:paragraph:]/.gen,
    :successful => true,
    :commit_identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
    :commit_metadata   => commit_metadata }
end

Integrity::Notifier.fixture(:irc) do
  class Integrity::Notifier::IRC < Integrity::Notifier::Base;end
  { :name => "IRC", :config => notifier_config }
end
