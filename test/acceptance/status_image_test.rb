require "helper/acceptance"

class StatusImageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to retrieve my project and build status as an image,
    In order to include it in web pages
  EOS

  scenario "Get public project status image" do
    successful_project = Project.gen :successful

    get "/#{successful_project.permalink}.png"

    assert_equal 200, response_code
    assert_equal "image/png", response_content_type
  end

  scenario "Get private project status image" do
    private_project = Project.gen :successful, :public => false

    get "/#{private_project.permalink}.png"

    assert_equal 401, response_code
    assert_equal "text/html;charset=utf-8", response_content_type

    login_as "admin", "test"

    get "/#{private_project.permalink}.png"

    assert_equal 200, response_code
    assert_equal "image/png", response_content_type
  end

  scenario "Get private project status image when images are always public" do
    Integrity.configure { |c|
      c.status_image_always_public = true
    }

    private_project = Project.gen :successful, :public => false

    get "/#{private_project.permalink}.png"

    assert_equal 200, response_code
    assert_equal "image/png", response_content_type
  end
end
