# frozen_string_literal: true

require 'test_helper'

class WatchedTransactionQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($txhash: String!) {
      watchedTransaction(txhash: $txhash) {
        id
        user {
          displayName
        }
        transactionObject
      }
    }
  EOS

  test 'watched transaction should work' do
    first_transaction = create(:watching_transaction)
    last_transaction = create(
      :watching_transaction,
      group_id: first_transaction.group_id,
      user: first_transaction.user,
      created_at: Date.current + 1
    )
    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: first_transaction.user },
      variables: { txhash: first_transaction.txhash }
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['watchedTransaction']

    assert_not_empty data,
                     'watchedTransaction type should work'
    assert_equal last_transaction.id, data['id'],
                 'should return last transaction from group'

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: first_transaction.user },
      variables: { txhash: 'NON_EXISTENT_TXHASH' }
    )

    assert_nil empty_result['data']['watchedTransaction'],
               'data should be empty on invalid txhash'
  end
end
