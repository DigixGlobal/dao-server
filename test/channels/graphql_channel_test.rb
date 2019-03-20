# frozen_string_literal: true

require 'test_helper'

class GraphqlChannelTest < ActionCable::Channel::TestCase
  QUERY = <<~EOS
    query {
      currentUser {
        email
        address
        username
        displayName
        createdAt
      }
    }
  EOS

  test 'should work' do
    stub_connection(current_user: create(:user))

    subscribe

    assert subscription.confirmed?,
           'subscribe should work'

    perform :execute,
            query: QUERY,
            variables: {}

    result = transmissions.last['result']

    assert_nil result['errors'],
               'schema should work'
    assert_not_empty result['data']['currentUser'],
                     'user should be the same'

    subscription.unsubscribe_from_channel
  end
end
