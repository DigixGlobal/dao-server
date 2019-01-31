# frozen_string_literal: true

require 'test_helper'

class UserQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($id: String!) {
      user(id: $id) {
        id
        address
        displayName
        email
        username
        isKycOfficer
        createdAt
      }
    }
  EOS

  test 'user should work' do
    officer = create(:kyc_officer_user)
    user = create(:user)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: { id: user.id.to_s }
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['user']

    assert_not_empty data,
                     'user type should work'

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: { id: 'NON_EXISTENT_ID' }
    )

    assert_nil empty_result['data']['user'],
               'data should be empty on invalid ID'
  end

  test 'should fail safely' do
    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: {}
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a regular user'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'
  end
end
