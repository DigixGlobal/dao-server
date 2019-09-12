# frozen_string_literal: true

require 'test_helper'

class WatchTransactionMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($transactionHash: String!, $transactionObject: JSONObject!, $signedTransaction: String!) {
      watchTransaction(input: { transactionHash: $transactionHash, transactionObject: $transactionObject, signedTransaction: $signedTransaction }) {
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

  test 'watch transaction mutation should work' do
    user = create(:user)
    attrs = attributes_for(:watch_transaction)

    tx_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_nil tx_result['errors'],
               'should work and have no errors'
    assert_empty tx_result['data']['watchTransaction']['errors'],
                 'should have no errors'

    data = tx_result['data']['watchTransaction']['watchedTransaction']

    assert_equal JSON.parse(attrs[:transactionObject]), data['transactionObject'],
                 'transactionObject should be the same'
  end

  test 'watch transaction should fail safely' do
    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a user'
  end
end
