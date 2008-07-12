require File.dirname(__FILE__) + '/lib/integrity'

Integrity.new

Integrity::Project.create do |p|
  p.name = 'Integrity'
  p.uri = 'git://github.com/foca/integrity.git'
  p.command = 'git-submodule init && git-submodule update && rake spec'
end

project = Integrity::Project.first(:name => 'Integrity')
result = project.build

puts "Error\n#{'='*6}"
puts result.error
puts "Output\n#{'='*6}"
puts result.output
puts "STATUS: #{result.human_readable_status}"
