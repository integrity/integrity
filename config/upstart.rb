desc 'Write upstart environment file'
task :write_upstart_envs do
  ruby_gemset  = File.read('.ruby-gemset').strip
  ruby_version = File.read('.ruby-version').strip
  template = File.read('upstart-envs.erb')
  File.new('upstart-envs', 'w').write(ERB.new(template).result(binding))
end
