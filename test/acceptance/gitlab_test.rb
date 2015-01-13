require 'helper/acceptance'

class GitLabTest < Test::Unit::AcceptanceTestCase
  include DataMapper::Sweatshop::Unique

  story <<-EOF
    As a project owner,
    I want to be able to use GitLab as a build trigger
    So that my project is built everytime I push to the Hub
  EOF

  class NoneBuilder
    def self.enqueue(_);end
  end

  setup do
    Integrity.configure do |c|
      c.auto_branch = false
      c.trim_branches = false
      c.build_all = false
    end
    Integrity.config.instance_variable_set(:@builder, NoneBuilder)
  end

  def payload(example='push')
    @payloads ||= JSON.parse(File.read(File.expand_path('../../fixtures/gitlab_payloads.json', __FILE__)))
    @payloads[example]
  end

  def gitlab_post(payload)
    post '/gitlab', {}, { 'rack.input' => StringIO.new(payload.to_json) }
  end

  def gen_project(options = {})
    branch = options[:branch] || 'master'
    uri = options[:uri] || payload['repository']['url']
    Project.gen(:my_test_project, :uri => uri, :command => 'true', :branch => branch)
  end

  scenario 'Receiving a payload for a branch that is not monitored' do
    gen_project(:branch => 'wip')

    gitlab_post payload
    visit '/my-test-project'

    assert_contain('No builds for this project')
  end

  scenario 'Receiving a deleted; trim_branches disabled' do
    Integrity.configure { |c| c.trim_branches = false }

    gen_project(:branch => 'experimental')

    gitlab_post payload('delete_branch')
    visit '/my-test-project'

    assert_contain('My Test Project')
  end

  scenario 'Receiving a deleted; trim_branches enabled' do
    Integrity.configure { |c| c.trim_branches = true }

    gen_project(:branch => 'experimental')

    gitlab_post payload('delete_branch')
    visit '/my-test-project'

    assert_contain('This is a 404')
  end

  scenario 'New branch; auto_branch disabled' do
    Integrity.configure { |c| c.auto_branch = false }

    gen_project
    gitlab_post payload('new_branch')
    visit '/my-test-project-experimental'

    assert_contain('This is a 404')
  end

  scenario 'New branch; auto_branch enabled' do
    Integrity.configure { |c| c.auto_branch = true }

    gen_project
    gitlab_post payload('new_branch')
    visit '/my-test-project-experimental'

    # project exist
    assert_contain('My Test Project (experimental)')

    # builds not exist because payload haven't commits
    assert_not_contain('(commit is missing)')
    assert_not_contain('Previous builds')
  end

  scenario 'Normal push; build head' do
    Integrity.configure { |c| c.build_all = false }

    gen_project

    visit '/my-test-project'
    assert_have_tag('#previous_builds li.build', :count => 0)

    gitlab_post payload

    visit '/my-test-project'
    assert_have_tag('#previous_builds li.build', :count => 1)
  end

  scenario 'Normal push; build all' do
    Integrity.configure { |c| c.build_all = true }

    gen_project

    visit '/my-test-project'
    assert_have_tag('#previous_builds li.build', :count => 0)

    gitlab_post payload

    visit '/my-test-project'
    assert_have_tag('#previous_builds li.build', :count => 3)
  end
end
