require 'test_helper'

class Api::V1::SrsControllerTest < ActionDispatch::IntegrationTest
  test "should get clients" do
    get srs_clients_url
    assert_response :success
  end

  test "should get streams" do
    get srs_streams_url
    assert_response :success
  end

  test "should get sessions" do
    get srs_sessions_url
    assert_response :success
  end

  test "should get dvrs" do
    get srs_dvrs_url
    assert_response :success
  end

  test "should get hls" do
    get srs_hls_url
    assert_response :success
  end

end
