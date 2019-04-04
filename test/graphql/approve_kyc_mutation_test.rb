# frozen_string_literal: true

require 'test_helper'

class ApproveKycMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($kycId: String!, $expirationDate: Date!) {
      approveKyc(input: { kycId: $kycId, expirationDate: $expirationDate}) {
        kyc {
          id
          status
          expirationDate
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'approve kyc mutation should work' do
    officer = create(:kyc_officer_user)
    kyc = create(:pending_kyc)
    attrs = normalize_attributes(
      kyc_id: kyc.id.to_s,
      expiration_date: generate(:future_date)
    )

    stub_request(:any, %r{kyc/approve})
      .to_return(body: { result: {} }.to_json)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['approveKyc']['errors'],
                 'should have no errors'

    data = result['data']['approveKyc']['kyc']

    assert_equal 'APPROVING', data['status'],
                 'should be approving'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: attrs
    )

    assert_not_empty repeat_result['data']['approveKyc']['errors'],
                     'should not allow reapproval of kycs'
  end

  test 'should fail safely' do
    officer = create(:kyc_officer_user)
    kyc = create(:pending_kyc)
    attrs = normalize_attributes(
      kyc_id: kyc.id.to_s,
      expiration_date: generate(:future_date)
    )

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: {}
    )

    assert_not_empty empty_result['errors'],
                     'should fail with empty data'

    not_found_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: attrs.merge('kycId' => 'NON_EXISTENT_ID')
    )

    assert_not_empty not_found_result['data']['approveKyc']['errors'],
                     'should fail if KYC is not found'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: attrs
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'

    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: attrs
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a normal user'
  end

  private

  def normalize_attributes(attrs)
    attrs[:expiration_date] = attrs[:expiration_date].strftime('%F')

    attrs.to_h.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
  end
end
