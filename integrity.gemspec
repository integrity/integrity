Gem::Specification.new do |s|
  s.name = %q{integrity}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nicol\303\241s Sanguinetti", "Simon Rozet"]
  s.date = %q{2008-12-08}
  s.default_executable = %q{integrity}
  s.description = %q{Your Friendly Continuous Integration server. Easy, fun and painless!}
  s.email = %q{contacto@nicolassanguinetti.info}
  s.executables = ["integrity"]
  s.files = ["README.markdown", "Rakefile", "VERSION.yml", "app.rb", "bin/integrity", "config/config.sample.ru", "config/config.sample.yml", "config/thin.sample.yml", "integrity.gemspec", "lib/integrity.rb", "lib/integrity/build.rb", "lib/integrity/builder.rb", "lib/integrity/core_ext/object.rb", "lib/integrity/core_ext/string.rb", "lib/integrity/core_ext/time.rb", "lib/integrity/notifier.rb", "lib/integrity/notifier/base.rb", "lib/integrity/project.rb", "lib/integrity/scm.rb", "lib/integrity/scm/git.rb", "lib/integrity/scm/git/uri.rb", "public/buttons.css", "public/reset.css", "public/spinner.gif", "vendor/sinatra-hacks/lib/hacks.rb", "views/build.haml", "views/build_info.haml", "views/error.haml", "views/home.haml", "views/integrity.sass", "views/layout.haml", "views/new.haml", "views/not_found.haml", "views/notifier.haml", "views/project.haml", "views/unauthorized.haml", "spec/spec_helper.rb", "spec/form_field_matchers.rb"]
  s.homepage = %q{http://integrityapp.com}
  s.post_install_message = %q{Run `integrity help` for information on how to setup Integrity.}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{integrity}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{The easy and fun Continuous Integration server}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<sinatra>, [">= 0.3.2"])
      s.add_runtime_dependency(%q<haml>, [">= 0"])
      s.add_runtime_dependency(%q<dm-core>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<dm-validations>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<dm-types>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<dm-timestamps>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<dm-aggregates>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<data_objects>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<do_sqlite3>, [">= 0.9.5"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<foca-sinatra-diddies>, [">= 0.0.2"])
      s.add_runtime_dependency(%q<rspec_hpricot_matchers>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
      s.add_runtime_dependency(%q<bcrypt-ruby>, [">= 0"])
    else
      s.add_dependency(%q<sinatra>, [">= 0.3.2"])
      s.add_dependency(%q<haml>, [">= 0"])
      s.add_dependency(%q<dm-core>, [">= 0.9.5"])
      s.add_dependency(%q<dm-validations>, [">= 0.9.5"])
      s.add_dependency(%q<dm-types>, [">= 0.9.5"])
      s.add_dependency(%q<dm-timestamps>, [">= 0.9.5"])
      s.add_dependency(%q<dm-aggregates>, [">= 0.9.5"])
      s.add_dependency(%q<data_objects>, [">= 0.9.5"])
      s.add_dependency(%q<do_sqlite3>, [">= 0.9.5"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<foca-sinatra-diddies>, [">= 0.0.2"])
      s.add_dependency(%q<rspec_hpricot_matchers>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<bcrypt-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<sinatra>, [">= 0.3.2"])
    s.add_dependency(%q<haml>, [">= 0"])
    s.add_dependency(%q<dm-core>, [">= 0.9.5"])
    s.add_dependency(%q<dm-validations>, [">= 0.9.5"])
    s.add_dependency(%q<dm-types>, [">= 0.9.5"])
    s.add_dependency(%q<dm-timestamps>, [">= 0.9.5"])
    s.add_dependency(%q<dm-aggregates>, [">= 0.9.5"])
    s.add_dependency(%q<data_objects>, [">= 0.9.5"])
    s.add_dependency(%q<do_sqlite3>, [">= 0.9.5"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<foca-sinatra-diddies>, [">= 0.0.2"])
    s.add_dependency(%q<rspec_hpricot_matchers>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<bcrypt-ruby>, [">= 0"])
  end
end
