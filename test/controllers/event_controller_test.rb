# frozen_string_literal: true

require 'test_helper'

class EventControllerTest < ActionDispatch::IntegrationTest
  setup :email_fixture

  test 'project created event should be handled' do
    path = event_path

    proposal = create(:proposal)
    payload = {
      event_type: 1,
      proposer: proposal.user.address,
      proposal_id: proposal.proposal_id
    }

    assert_self_nonce_increased do
      info_post path,
                payload: payload
    end

    assert_response :success,
                    'should work'
    assert_match 'result', @response.body,
                 'response should be ok'

    assert_emails 1
  end

  test 'project endorsed event should be handled' do
    path = event_path

    proposal = create(:proposal)
    payload = {
      event_type: 2,
      proposer: proposal.user.address,
      proposal_id: proposal.proposal_id
    }

    assert_self_nonce_increased do
      info_post path,
                payload: payload
    end

    assert_response :success,
                    'should work'
    assert_match 'result', @response.body,
                 'response should be ok'

    assert_emails 1
  end

  test 'handle event should fail safely' do
    path = event_path

    proposal = create(:proposal)
    payload = {
      event_type: 0,
      proposer: proposal.user.address,
      proposal_id: proposal.proposal_id
    }

    post path,
         params: { payload: payload }.to_json

    assert_response :forbidden,
                    'should fail without a signature'

    info_post path,
              payload: {}

    assert_response :success,
                    'should work safely even with empty data'
    assert_match 'error', @response.body,
                 'should contain error'

    info_post path,
              payload: payload

    assert_response :success,
                    'should handle invalid events'
    assert_match 'invalid_event_type', @response.body,
                 'should contain invalid event type'

    info_post path,
              payload: {
                event_type: 1,
                proposer: '0xMEOW',
                proposal_id: 'NON_EXISTENT_ID'
              }

    assert_response :not_found,
                    'should handle missing proposals'
  end
end
