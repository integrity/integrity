require File.dirname(__FILE__) + '/lib/integrity'

Integrity.new

Integrity::Project.create(
  :name    => 'Integrity', 
  :uri     => 'git://github.com/foca/integrity.git',
  :command => 'echo `pwd`; git-submodule update --init && rake'
)

project = Integrity::Project.first(:name => 'Integrity')
result = project.build

puts "Error\n#{'='*6}"
puts result.error
puts "Output\n#{'='*6}"
puts result.output
puts "STATUS: #{result.human_readable_status}"
