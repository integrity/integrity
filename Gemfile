source 'https://rubygems.org'

gem 'mysql2'
gem 'data_mapper', '~> 1.2'
gem 'dm-mysql-adapter'

gem 'rack-contrib'

# Workaround until https://github.com/datamapper/dm-core/issues/242
# is fixed in a released version of datamapper.
gem 'dm-core', git: 'git://github.com/datamapper/dm-core', branch: 'release-1.2'

gem 'haml'
gem 'sass'

gem 'chronic_duration'
gem 'sinatra'
gem 'sinatra-authorization'

gem 'bcat'
gem 'rake'
gem 'rconfig', '0.4.3.1', require: 'rconfig'

gem 'capistrano', '2.15.4'
gem 'rvm-capistrano', '1.3.4'
gem 'capistrano-deploytags'

# Dependency for Resque builder
gem 'resque'
gem 'unicorn'

group :web_servers do
  # gem 'thin'
end

# These are dependencies for the various notifiers. Uncomment as appropriate.
group :notifiers do
  # gem 'pony', '1.1'                             # E-mail
  # gem 'aws-ses', '~> 0.4.3', require: 'aws/ses' # SES E-mail
  # gem 'broach', '0.2.1'                         # Campfire
  # gem 'nap', '0.4'                              # HTTP
  # gem 'bunny', '0.6.0'                          # AMQP
end

# Dependencies for DelayedJob builder
group :delayed_job do
  # gem 'delayed_job'
  # gem 'delayed_job_active_record'
end

# Dependencies for DB's - If you're using pg or mysql instead of sqlite
group :databases do
  # gem 'pg'
  # gem 'dm-postgres-adapter'
  # gem 'do_postgres'  # If installing dependencies with rpg.
  # gem 'mysql'
  # gem 'dm-mysql-adapter'
end

gem 'debugger'
gem 'pry'
gem 'pry-debugger'

group :development do
end

# Development dependencies
group :test do
  gem 'aws-ses', '~> 0.4.3', require: 'aws/ses'
  gem 'extlib'
  gem 'sqlite3'
  gem 'delayed_job'
  gem 'delayed_job_active_record'
  gem 'activerecord',    '~> 3.2'
  gem 'i18n'
  gem 'rr'
  gem 'mocha'
  gem 'redgreen'
  gem 'dm-sweatshop', git: 'git://github.com/p/dm-sweatshop-without-parsetree', branch: 'integrity'
  gem 'randexp'
  gem 'pony'
  gem 'rack-test'
  gem 'nokogiri'
  gem 'hpricot'
  gem 'contest'
  gem 'webrat'
  gem 'broach'
  gem 'nap'
  gem 'bunny'
  gem 'shout-bot'
  gem 'webmock'
  gem 'turn'
  gem 'timecop'
end
