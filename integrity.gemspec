Gem::Specification.new do |s|
  s.name = %q{integrity}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nicol\303\241s Sanguinetti", "Simon Rozet"]
  s.date = %q{2008-12-10}
  s.default_executable = %q{integrity}
  s.description = %q{Your Friendly Continuous Integration server. Easy, fun and painless!}
  s.email = %q{contacto@nicolassanguinetti.info}
  s.executables = ["integrity"]
  s.files = ["README.markdown", "Rakefile", "VERSION.yml", "app.rb", "bin/integrity", "config/config.sample.ru", "config/config.sample.yml", "config/thin.sample.yml", "integrity.gemspec", "lib/integrity.rb", "lib/integrity/build.rb", "lib/integrity/project_builder.rb", "lib/integrity/core_ext/object.rb", "lib/integrity/core_ext/string.rb", "lib/integrity/core_ext/time.rb", "lib/integrity/notifier.rb", "lib/integrity/notifier/base.rb", "lib/integrity/project.rb", "lib/integrity/scm.rb", "lib/integrity/scm/git.rb", "lib/integrity/scm/git/uri.rb", "public/buttons.css", "public/reset.css", "public/spinner.gif", "vendor/sinatra-hacks/lib/hacks.rb", "views/build.haml", "views/build_info.haml", "views/error.haml", "views/home.haml", "views/integrity.sass", "views/layout.haml", "views/new.haml", "views/not_found.haml", "views/notifier.haml", "views/project.haml", "views/unauthorized.haml", "spec/spec_helper.rb", "spec/form_field_matchers.rb"]
  s.homepage = %q{http://integrityapp.com}
  s.post_install_message = %q{Run `integrity help` for information on how to setup Integrity.}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{integrity}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{The easy and fun Continuous Integration server}

  deps = [
    [%q<sinatra>, [">= 0.3.2"]],
    [%q<haml>, [">= 0"]],
    [%q<dm-core>, [">= 0.9.5"]],
    [%q<dm-validations>, [">= 0.9.5"]],
    [%q<dm-types>, [">= 0.9.5"]],
    [%q<dm-timestamps>, [">= 0.9.5"]],
    [%q<dm-aggregates>, [">= 0.9.5"]],
    [%q<data_objects>, [">= 0.9.5"]],
    [%q<do_sqlite3>, [">= 0.9.5"]],
    [%q<json>, [">= 0"]],
    [%q<foca-sinatra-diddies>, [">= 0.0.2"]],
    [%q<rspec_hpricot_matchers>, [">= 0"]],
    [%q<thor>, [">= 0"]],
    [%q<bcrypt-ruby>, [">= 0"]]
  ]
  
  deps.each do |dep|
    if s.respond_to? :specification_version && Gem::Specification::CURRENT_SPECIFICATION_VERSION >= 3 then
      s.specification_version = 2
      s.add_runtime_dependency(*dep)
    else
      s.add_dependency(*dep)
    end
  end
end
