desc 'Write upstart environment file'
task :write_upstart_envs do
  ruby_gemset = File.new(".ruby-gemset","r").read.chomp
  ruby_version = File.new(".ruby-version","r").read.chomp
  template = File.read("upstart-envs.erb")
  File.new('upstart-envs', 'w').write(ERB.new(template).result(binding))
end
