Gem::Specification.new do |s|
  s.name    = "integrity"
  s.version = "0.1.9.0"
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

  s.files = %w(
    Rakefile
    README.markdown
    bin/integrity
    lib/integrity
    lib/integrity/project_builder.rb
    lib/integrity/core_ext
    lib/integrity/core_ext/object.rb
    lib/integrity/notifier.rb
    lib/integrity/helpers.rb
    lib/integrity/installer.rb
    lib/integrity/app.rb
    lib/integrity/build.rb
    lib/integrity/scm
    lib/integrity/scm/git.rb
    lib/integrity/scm/git
    lib/integrity/scm/git/uri.rb
    lib/integrity/author.rb
    lib/integrity/project.rb
    lib/integrity/migrations.rb
    lib/integrity/scm.rb
    lib/integrity/helpers
    lib/integrity/helpers/rendering.rb
    lib/integrity/helpers/authorization.rb
    lib/integrity/helpers/forms.rb
    lib/integrity/helpers/resources.rb
    lib/integrity/helpers/breadcrumbs.rb
    lib/integrity/helpers/pretty_output.rb
    lib/integrity/helpers/urls.rb
    lib/integrity/notifier
    lib/integrity/notifier/base.rb
    lib/integrity/notifier/test_helpers.rb
    lib/integrity/commit.rb
    lib/integrity.rb
    views/not_found.haml
    views/notifier.haml
    views/new.haml
    views/error.haml
    views/unauthorized.haml
    views/layout.haml
    views/project.builder
    views/_commit_info.haml
    views/project.haml
    views/build.haml
    views/home.haml
    views/integrity.sass
    public/buttons.css
    public/spinner.gif
    public/reset.css
    config/config.ru
    config/thin.sample.yml
    config/config.sample.ru
    config/config.yml
    config/config.sample.yml
    test/helpers.rb
    test/acceptance
    test/acceptance/build_notifications_test.rb
    test/acceptance/notifier_test.rb
    test/acceptance/manual_build_project_test.rb
    test/acceptance/helpers.rb
    test/acceptance/stylesheet_test.rb
    test/acceptance/api_test.rb
    test/acceptance/project_syndication_test.rb
    test/acceptance/error_page_test.rb
    test/acceptance/browse_project_test.rb
    test/acceptance/edit_project_test.rb
    test/acceptance/delete_project_test.rb
    test/acceptance/create_project_test.rb
    test/acceptance/installer_test.rb
    test/acceptance/browse_project_builds_test.rb
    test/unit
    test/unit/helpers_test.rb
    test/unit/migrations_test.rb
    test/unit/notifier_test.rb
    test/unit/project_builder_test.rb
    test/unit/build_test.rb
    test/unit/project_test.rb
    test/unit/commit_test.rb
    test/unit/scm_test.rb
    test/unit/integrity_test.rb
    test/helpers
    test/helpers/expectations.rb
    test/helpers/acceptance.rb
    test/helpers/acceptance
    test/helpers/acceptance/email_notifier.rb
    test/helpers/acceptance/textfile_notifier.rb
    test/helpers/acceptance/git_helper.rb
    test/helpers/expectations
    test/helpers/expectations/have.rb
    test/helpers/expectations/be_a.rb
    test/helpers/expectations/predicates.rb
    test/helpers/expectations/change.rb
    test/helpers/fixtures.rb
    test/helpers/initial_migration_fixture.sql
  )
end
