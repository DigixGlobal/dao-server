# frozen_string_literal: true

require 'test_helper'

class KycQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($id: String!) {
      kyc(id: $id) {
        id
      }
    }
  EOS

  test 'kycQueryTest should work' do
    officer = create(:kyc_officer_user)
    kyc = create(:kyc)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: { id: kyc.id.to_s }
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['kyc']

    assert_not_empty data,
                     'kyc type should work'

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: { id: 'NON_EXISTENT_ID' }
    )

    assert_nil empty_result['data']['kyc'],
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
