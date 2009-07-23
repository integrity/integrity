Gem::Specification.new do |s|
  s.name    = "integrity"
  s.version = "0.1.10"
  s.date    = "2009-05-14"

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

  s.add_dependency "bob", [">= 0.3"]
  s.add_dependency "bobette", [">= 0.0.4"]

  s.add_dependency "sinatra", ["= 0.9.2"]
  s.add_dependency "sinatra-authorization"

  s.add_dependency "haml",    [">= 2.0.0"]
  s.add_dependency "json"

  s.add_dependency "data_mapper", ["= 0.9.11"]
  s.add_dependency "uuidtools"   # required by dm-types
  s.add_dependency "bcrypt-ruby" # required by dm-types

  s.add_dependency "thor"

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency "rr"
    s.add_development_dependency "do_sqlite3"
    s.add_development_dependency "dm-sweatshop"
    s.add_development_dependency "ParseTree" # required by dm-sweatshop
    s.add_development_dependency "jeremymcanally-context"
    s.add_development_dependency "jeremymcanally-matchy"
    s.add_development_dependency "jeremymcanally-pending"
    s.add_development_dependency "foca-storyteller"
  end

  s.files = %w[
AUTHORS
CHANGES
LICENSE
README.md
Rakefile
bin/integrity
config/config.sample.ru
config/config.sample.yml
config/heroku/.gems
config/heroku/Rakefile
config/heroku/config.ru
config/heroku/integrity-config.rb
config/thin.sample.yml
integrity.gemspec
lib/integrity.rb
lib/integrity/app.rb
lib/integrity/author.rb
lib/integrity/build.rb
lib/integrity/buildable_project.rb
lib/integrity/commit.rb
lib/integrity/core_ext/object.rb
lib/integrity/helpers.rb
lib/integrity/helpers/authorization.rb
lib/integrity/helpers/breadcrumbs.rb
lib/integrity/helpers/pretty_output.rb
lib/integrity/helpers/rendering.rb
lib/integrity/helpers/resources.rb
lib/integrity/helpers/urls.rb
lib/integrity/installer.rb
lib/integrity/migrations.rb
lib/integrity/notifier.rb
lib/integrity/notifier/base.rb
lib/integrity/notifier/test.rb
lib/integrity/notifier/test/fixtures.rb
lib/integrity/notifier/test/hpricot_matcher.rb
lib/integrity/project.rb
lib/integrity/project/notifiers.rb
public/buttons.css
public/reset.css
public/spinner.gif
test/acceptance/browse_project_builds_test.rb
test/acceptance/browse_project_test.rb
test/acceptance/build_notifications_test.rb
test/acceptance/create_project_test.rb
test/acceptance/delete_project_test.rb
test/acceptance/edit_project_test.rb
test/acceptance/error_page_test.rb
test/acceptance/github_test.rb
test/acceptance/installer_test.rb
test/acceptance/manual_build_project_test.rb
test/acceptance/not_found_page_test.rb
test/acceptance/notifier_test_test.rb
test/acceptance/project_syndication_test.rb
test/acceptance/stylesheet_test.rb
test/acceptance/unauthorized_page_test.rb
test/helpers.rb
test/helpers/acceptance.rb
test/helpers/acceptance/email_notifier.rb
test/helpers/acceptance/notifier_helper.rb
test/helpers/acceptance/textfile_notifier.rb
test/helpers/expectations.rb
test/helpers/expectations/be_a.rb
test/helpers/expectations/change.rb
test/helpers/expectations/have.rb
test/helpers/expectations/predicates.rb
test/helpers/initial_migration_fixture.sql
test/unit/build_test.rb
test/unit/commit_test.rb
test/unit/helpers_test.rb
test/unit/integrity_test.rb
test/unit/migrations_test.rb
test/unit/notifier/base_test.rb
test/unit/notifier_test.rb
test/unit/project_test.rb
views/_commit_info.haml
views/build.haml
views/error.haml
views/home.haml
views/integrity.sass
views/layout.haml
views/new.haml
views/not_found.haml
views/notifier.haml
views/project.builder
views/project.haml
views/unauthorized.haml
]
end
