require "helper/acceptance"

class ProjectListTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to retrieve project list in JSON,
    To operate on it programmatically
  EOS

  setup do
    Project.all.each do |project|
      project.destroy
    end
  end

  scenario "Get public project list JSON format" do
    successful_project = Project.gen :successful
    # XXX figure out how to do this better.
    # A successful project creates 3 more projects for its builds.
    Project.all.each do |project|
      if project != successful_project
        project.destroy
      end
    end
    assert_equal 1, Project.count

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal "application/json; charset=utf-8", response_content_type

    assert_equal({
      "projects" => [
        {
          "name" => successful_project.name,
          "status" => "success"
        }
      ]
    }, parse_response_as_json)
  end

  scenario "Get list of public projects only if not authenticated" do
    public_project = Project.gen :successful, :name => 'public project'
    private_project = Project.gen :successful, :public => false, :name => 'private project'
    # XXX figure out how to do this better.
    # A successful project creates 3 more projects for its builds.
    Project.all.each do |project|
      if project != public_project && project != private_project
        project.destroy
      end
    end
    assert_equal 2, Project.count

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal "application/json; charset=utf-8", response_content_type

    assert_equal({
      "projects" => [
        {
          "name" => public_project.name,
          "status" => "success"
        }
      ]
    }, parse_response_as_json)
  end

  scenario "Get list of public and private projects only if authenticated" do
    public_project = Project.gen :successful, :name => 'public project'
    private_project = Project.gen :successful, :public => false, :name => 'private project'
    # XXX figure out how to do this better.
    # A successful project creates 3 more projects for its builds.
    Project.all.each do |project|
      if project != public_project && project != private_project
        project.destroy
      end
    end
    assert_equal 2, Project.count

    login_as "admin", "test"

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal "application/json; charset=utf-8", response_content_type

    # Integrity sorts the project list
    assert_equal({
      "projects" => [
        {
          "name" => private_project.name,
          "status" => "success"
        },
        {
          "name" => public_project.name,
          "status" => "success"
        },
      ]
    }, parse_response_as_json)
  end
end
