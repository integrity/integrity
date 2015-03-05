# Head of Engineering
if !Integrity::User.first(username: 'kenberland')
  u = Integrity::User.new
  u.name = 'Ken Berland'
  u.email = 'ken@grandrounds.com'
  u.username = 'kenberland'
  u.title = 'Head of Engineering'
  u.gh_uid = '681863'
  u.admin = true
  u.save
end

# Leads
if !Integrity::User.first(username: 'beghbali')
  u = Integrity::User.new
  u.name = 'Bashir Eghbali'
  u.email = 'bashir@grandrounds.com'
  u.username = 'beghbali'
  u.title = 'Technical Lead'
  u.gh_uid = '998422'
  u.admin = true
  u.save
end

if !Integrity::User.first(username: 'rahmal')
  u = Integrity::User.new
  u.name = 'Rahmal Conda'
  u.email = 'rahmal@grandrounds.com'
  u.username = 'rahmal'
  u.title = 'Technical Lead'
  u.gh_uid = '122263'
  u.admin = true
  u.save
end

if !Integrity::User.first(username: 'webflint')
  u = Integrity::User.new
  u.name = 'Brett Suwyn'
  u.email = 'brett@grandrounds.com'
  u.username = 'webflint'
  u.title = 'Technical Lead'
  u.gh_uid = '252220'
  u.admin = true
  u.save
end

if !Integrity::User.first(username: 'cobbr2')
  u = Integrity::User.new
  u.name = 'Rick Cobb'
  u.email = 'rick@grandrounds.com'
  u.username = 'cobbr2'
  u.title = 'Architect/Lead'
  u.gh_uid = '249301'
  u.admin = true
  u.save
end

if !Integrity::User.first(username: 'soonahn')
  u = Integrity::User.new
  u.name = 'Justin Ahn'
  u.email = 'justin@grandrounds.com'
  u.username = 'soonahn'
  u.title = 'Architect/Senior Engineer'
  u.gh_uid = '1271952'
  u.admin = true
  u.save
end

# Engineers
if !Integrity::User.first(username: 'timz1290')
  u = Integrity::User.new
  u.name = 'Tim Wang'
  u.email = 'tim.wang@grandrounds.com'
  u.username = 'timz1290'
  u.title = 'Engineer'
  u.gh_uid = '1915687'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'mpgaillard')
  u = Integrity::User.new
  u.name = 'Michael Pena'
  u.email = 'michael.pena@grandrounds.com'
  u.username = 'mpgaillard'
  u.title = 'Engineer'
  u.gh_uid = '2374007'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'mike809')
  u = Integrity::User.new
  u.name = 'Michael Romano'
  u.email = 'michael@grandrounds.com'
  u.username = 'mike809'
  u.title = 'Engineer'
  u.gh_uid = '3720790'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'OAGr')
  u = Integrity::User.new
  u.name = 'Ozzie Gooen'
  u.email = 'ozzie@grandrounds.com'
  u.username = 'OAGr'
  u.title = 'Engineer'
  u.gh_uid = '377065'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'kquet')
  u = Integrity::User.new
  u.name = 'Kael Quet'
  u.email = 'kael.quet@grandrounds.com'
  u.username = 'kquet'
  u.title = 'Engineer'
  u.gh_uid = '2567715'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'Bojole')
  u = Integrity::User.new
  u.name = 'Bojil Velinov'
  u.email = 'bojil.velinov@grandrounds.com'
  u.username = 'Bojole'
  u.title = 'Engineer'
  u.gh_uid = '2790158'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'alexebird')
  u = Integrity::User.new
  u.name = 'Alex Bird'
  u.email = 'alex.bird@grandrounds.com'
  u.username = 'alexebird'
  u.title = 'Engineer'
  u.gh_uid = '120678'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'andrewpurcell')
  u = Integrity::User.new
  u.name = 'Andrew Purcell'
  u.email = 'andrew.purcell@grandrounds.com'
  u.username = 'andrewpurcell'
  u.title = 'Engineer'
  u.gh_uid = '466873'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'glacier')
  u = Integrity::User.new
  u.name = 'Grace Li'
  u.email = 'grace.li@grandrounds.com'
  u.username = 'glacier'
  u.title = 'Engineer'
  u.gh_uid = '233731'
  u.admin = false
  u.save
end

# Interns
if !Integrity::User.first(username: 'mhfung')
  u = Integrity::User.new
  u.name = 'Martin Fung'
  u.email = 'martin.fung@grandrounds.com'
  u.username = 'mhfung'
  u.title = 'Intern'
  u.gh_uid = '8070503'
  u.admin = false
  u.save
end

# Ops/IT
if !Integrity::User.first(username: 'hectorgarza1')
  u = Integrity::User.new
  u.name = 'Hector Garza'
  u.email = 'hector.garza@grandrounds.com'
  u.username = 'hectorgarza1'
  u.title = 'Ops/IT'
  u.gh_uid = '10160804'
  u.admin = false
  u.save
end

if !Integrity::User.first(username: 'kmoore-grnds')
  u = Integrity::User.new
  u.name = 'Kevin Moore'
  u.email = 'kevin@grandrounds.com'
  u.username = 'kmoore-grnds'
  u.title = 'Ops/IT'
  u.gh_uid = '7342515'
  u.admin = false
  u.save
end