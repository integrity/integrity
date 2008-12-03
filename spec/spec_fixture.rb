require 'rubygems'
require 'dm-sweatshop'

include DataMapper::Sweatshop::Unique

class Array
  def pick
    self[rand(self.length)]
  end
end

Integrity::Project.fixture {
  name = /\w+/.gen

  { :name       => unique { name.capitalize },
    :permalink  => name,
    :uri        => "git://github.com/#{/\w+/.gen}/#{name}",
    :branch     => %w[master bug_4567 build-in-badground].pick,
    :command    => "rake master",
    :public     => true,
    :building   => false,
    :builds     => (1..30).of { Integrity::Build.gen }}
}

Integrity::Build.fixture {{
  :output     => /[:paragraph:]/.gen,
  :successful => true,
  :commit_identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
  :commit_metadata   => {}.to_yaml,
}}
