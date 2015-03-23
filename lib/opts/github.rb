require 'octokit'

Octokit.configure do |c|
  c.access_token = ENV['GITHUB_READ_TOKEN']
end
