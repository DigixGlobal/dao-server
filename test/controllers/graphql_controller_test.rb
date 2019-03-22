# frozen_string_literal: true

require 'test_helper'

class GraphQLControllerTest < ActionDispatch::IntegrationTest
  test 'ip addresses should work' do
    post api_path,
         params: {},
         headers: { 'X-Forwarded-For' => '' }

    assert_response :success,
                    'should work with blank header'

    post api_path,
         params: {},
         headers: { 'X-Forwarded-For' => '127.0.0.1' }

    assert_response :success,
                    'should work with a single ip'

    post api_path,
         params: {},
         headers: { 'X-Forwarded-For' => '203.0.113.195, 70.41.3.18, 150.172.238.178' }

    assert_response :success,
                    'should work with multiple ips'

    post api_path,
         params: {},
         headers: {}

    assert_response :success,
                    'should work without the header'
  end
end
