require 'rubygems'
require 'dm-sweatshop'

class Array
  def one_of
    self[rand(self.length)]
  end
end

Integrity::Project.fixture {{
  :name       => (name = /\w+/.gen),
  :permalink  => name,
  :uri        => "git://github.com/#{/\w+/.gen}/#{name}",
  :branch     => %(master bug_4567 build-in-badground).one_of,
  :command    => "rake master",
  :public     => true,
  :building   => false,
  :builds     => (1..30).of { Integrity::Build.gen }
}}

Integrity::Build.fixture {{
  :output     => /[:paragraph:]/.gen,
  :successful => true,
  :commit_identifier => Digest::SHA1.hexdigest(/[:paragraph:]/.gen),
  :commit_metadata   => {}.to_yaml,
}}
