# frozen_string_literal: true

require 'test_helper'

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'create new proposal should work' do
    payload = attributes_for(:info_proposal)
    create(:user, address: payload.fetch(:proposer))
    path = proposals_create_path

    post path,
         params: { payload: payload }.to_json,
         headers: info_server_headers(
           'POST',
           path,
           payload
         )

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post path,
         params: { payload: payload }.to_json

    assert_response :forbidden,
                    'should fail without authorization'
  end
end
