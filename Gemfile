source "http://rubygems.org"

gem "dm-sqlite-adapter",     "1.0.2"
gem "dm-core",               "1.0.2"
gem "dm-timestamps",         "1.0.2"
gem "dm-types",              "1.0.2"
gem "dm-migrations",         "1.0.2"
gem "dm-aggregates",         "1.0.2"
gem "dm-validations",        "1.0.2"
if RUBY_VERSION < '1.9'
  # 0.10.7 seems to work fine, at least for tests,
  # but produces a huge amount of spam due to:
  # https://github.com/datamapper/dm-do-adapter/issues/4
  gem "do_sqlite3",          "0.10.2"
else
  # do_sqlite3 < 0.10.7 uses DateTime.new!, which was removed
  # in ruby 1.9 somewhere before 1.9.3-preview1.
  gem "do_sqlite3",          "0.10.7"
end
gem "rake",                  "0.8.7"
gem "haml",                  "3.0.25"
gem "addressable",           "2.2.2"
gem "json",                  "1.4.6"
gem "sinatra",               "1.1.2"
gem "sinatra-authorization", "1.0.0"
gem "bcat",                  "0.5.2"
gem "rack",                  "1.1.0"

# If you want to use Thin:
# gem "thin"

# If you want to use Unicorn:
# gem "unicorn"

# These are dependencies for the various notifiers. Uncomment as appropriate.
# = Email
# gem "pony", "1.1"

# = Campfire
# gem "broach", "0.2.1"
# gem "nap", "0.4"

# = AMQP
# gem "bunny", "0.6.0"

# = Notifo
# gem "notifo", "0.1.0"

# = Dependencies for the :dj builder
# gem "sqlite3-ruby", "1.3.2"
# gem "activerecord", "3.0.3"
# gem "delayed_job", "2.1.2"
# If running on ruby 1.9 with psych:
# https://github.com/collectiveidea/delayed_job/issues/199
# gem "delayed_job", "3.0.0"
# gem "delayed_job_active_record", "0.3.1"

# = Dependency for the :resque builder
# gem "resque", "1.10.0"

# Uncomment if you're using pg or mysql instead of sqlite
# gem "pg"
# gem "dm-postgres-adapter", "1.0.2"

# gem "mysql"
# gem "dm-mysql-adapter", "1.0.2"

# = Development dependencies.
group :test do
  gem "ruby-debug",      "0.10.4" if RUBY_VERSION < '1.9'
  gem "extlib",          "0.9.15"
  gem "sqlite3-ruby",    "~> 1.3.2"
  gem "delayed_job",     "2.1.2"
  # If running on ruby 1.9 with psych:
  # https://github.com/collectiveidea/delayed_job/issues/199
  # gem "delayed_job",   "3.0.0"
  # gem "delayed_job_active_record", "0.3.1"
  gem "activerecord",    "3.0.3"
  gem "i18n",            "0.5.0"
  gem "rr",              "1.0.2"
  gem "mocha",           "0.9.10"
  gem "redgreen",        "1.2.2"
  gem "dm-sweatshop",    "~> 1.0.2"
  gem "randexp",         "~> 0.1.6"
  gem "pony",            "1.1"
  gem "notifo",          "0.1.0"
  gem "rack-test",       "0.5.7"
  gem "nokogiri",        "1.4.4"
  gem "hpricot",         "0.8.3"
  gem "contest",         "0.1.2"
  gem "webrat",          "0.7.3"
  gem "broach",          "0.2.1"
  gem "nap",             "0.4"
  gem "bunny",           "0.6.0"
  gem "webmock",         "1.6.2"
  gem "turn",            "0.8.1"
end
