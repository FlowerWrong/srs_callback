require 'test_helper'

class LiveControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get live_index_url
    assert_response :success
  end

end
