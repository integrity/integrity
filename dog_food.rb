require File.dirname(__FILE__) + '/lib/integrity'

Integrity.new
include Integrity

project = Project.first(:name => "Integrity") || begin
  Integrity::Project.create(
    :name    => 'Integrity', 
    :uri     => 'git://github.com/foca/integrity.git',
    :command => 'git submodule update --init && rake'
  )
  Project.first(:name => 'Integrity')
end
  
result = project.build

puts "Output\n#{'='*6}"
puts result.output
puts "STATUS: #{result.human_readable_status}"
