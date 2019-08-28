# frozen_string_literal: true

require 'test_helper'

class ResendTransactionMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($id: ID!, $transactionHash: String!, $transactionObject: JSONObject!, $signedTransaction: String!) {
      resendTransaction(input: { id: $id, transactionHash: $transactionHash, transactionObject: $transactionObject, signedTransaction: $signedTransaction }) {
        watchedTransaction {
          id
          user {
            address
          }
          transactionObject
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'resend transaction mutation should work' do
    old_transaction = create(:watching_transaction)
    attrs = attributes_for(:watch_transaction_resend, id: old_transaction.id)

    tx_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: old_transaction.user },
      variables: attrs
    )

    assert_nil tx_result['errors'],
               'should work and have no errors'
    assert_empty tx_result['data']['resendTransaction']['errors'],
                 'should have no errors'

    data = tx_result['data']['resendTransaction']['watchedTransaction']

    assert_equal JSON.parse(attrs[:transactionObject])['nonce'], data['transactionObject']['nonce'],
                 'nonce should be the same'
  end

  test 'resend transaction should fail safely' do
    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a user'

    old_transaction = create(:watching_transaction)
    attrs = attributes_for(:watch_transaction_resend)

    invalid_group_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: old_transaction.user },
      variables: attrs
    )

    assert_not_empty invalid_group_result['data']['resendTransaction']['errors'],
                     'should fail with invalid id'

    invalid_nonce_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: old_transaction.user },
      variables: attributes_for(:watch_transaction, id: old_transaction.id)
    )

    assert_not_empty invalid_nonce_result['data']['resendTransaction']['errors'],
                     'should fail with invalid nonce'
  end
end
