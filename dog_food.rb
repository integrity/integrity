require File.dirname(__FILE__) + '/lib/integrity'

Integrity.new
project = Integrity::Project.new
project.name = 'Integrity'
project.uri = 'git://github.com/foca/integrity.git'
project.command = 'git-submodule init && git-submodule update && rake spec'

result = project.build

puts "Error\n#{'='*6}"
puts result.error
puts "Output\n#{'='*6}"
puts result.output
puts "STATUS: #{result.human_readable_status}"
