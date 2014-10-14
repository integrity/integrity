set :rails_env, 'development'

server 'integritydevelopment01', :rvm, :worker, :webapp, :db
server 'integritydevelopment02', :rvm, :worker
#server 'bid01', :rvm, :worker, :webapp, :db
