require "helper/acceptance"

class StatusTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to retrieve my project status in JSON,
    In order to use it in applications
  EOS

  scenario "Get public project info in JSON format" do
    successful_project = Project.gen :successful

    get "/#{successful_project.permalink}.json"

    assert_equal "application/json; charset=utf-8", response_content_type

    assert_equal parse_response_as_json, {
      "project" => {
        "name" => successful_project.name,
        "status" => "success"
      }
    }
  end

  scenario "Get private project info in JSON format" do
    private_project = Project.gen :public => false

    get "/#{private_project.permalink}.json"

    assert_equal "application/json; charset=utf-8", response_content_type

    assert_equal 401, response_code

    json = {
      "error" => {
        "code" => 401,
        "message" => "Authorization Required"
      }
    }

    assert_equal json, parse_response_as_json

    login_as "admin", "test"

    get "/#{private_project.permalink}.json"

    json = {
      "project" => {
        "name" => private_project.name,
        "status" => "blank"
      }
    }

    assert_equal json, parse_response_as_json
  end
end
