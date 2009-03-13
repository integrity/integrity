# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = "integrity"
  s.version = "0.1.9"
  s.date    = "2009-03-13"

  s.description = "Your Friendly Continuous Integration server. Easy, fun and painless!"
  s.summary     = "The easy and fun Continuous Integration server"
  s.homepage    = "http://integrityapp.com"

  s.authors = ["Nicolás Sanguinetti", "Simon Rozet"]
  s.email   = "info@integrityapp.com"

  s.require_paths = ["lib"]
  s.executables   = ["integrity"]

  s.post_install_message = "Run `integrity help` for information on how to setup Integrity."
  s.rubyforge_project = "integrity"
  s.has_rdoc          = false
  s.rubygems_version  = "1.3.1"

  s.add_dependency "sinatra", [">= 0.9.1.1"]
  s.add_dependency "haml",    [">= 2.0.0"]
  s.add_dependency "data_mapper", [">= 0.9.10"]
  s.add_dependency "uuidtools"   # required by dm-types
  s.add_dependency "bcrypt-ruby" # required by dm-types
  s.add_dependency "json"
  s.add_dependency "foca-sinatra-ditties", [">= 0.0.3"]
  s.add_dependency "thor"
end
