require 'test_helper'

class Api::V1::TranscodesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get transcodes_create_url
    assert_response :success
  end

end
