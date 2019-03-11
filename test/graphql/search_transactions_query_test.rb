# frozen_string_literal: true

require 'test_helper'

class SearchTransactionsQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($status: TransactionStatusEnum) {
      searchTransactions(status: $status) {
        edges {
          node {
            id
            title
            txhash
            status
            blockNumber
            user {
              displayName
            }
            transactionType
            project
            createdAt
          }
        }
      }
    }
  EOS

  test 'search transactions should work' do
    user = create(:user)

    create_list(:transaction, 3)
    create_list(:transaction, 3, user: user)
    create_list(:transaction_claim_result, 4, user: user)

    transaction_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: {}
    )

    assert_nil transaction_result['errors'],
               'should work and have no errors'
    assert_not_empty transaction_result['data']['searchTransactions'],
                     'should have at data'

    transaction_data = transaction_result['data']['searchTransactions']['edges']
                       .map { |edge| edge['node'] }

    assert_equal 7, transaction_data.size,
                 'should have 7 transactions'

    pending_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { status: 'PENDING' }
    )

    assert_nil pending_result['errors'],
               'should work with pending status and have no errors'
    assert_not_empty pending_result['data']['searchTransactions'],
                     'should have at data'

    pending_data = pending_result['data']['searchTransactions']['edges']
                   .map { |edge| edge['node'] }

    assert_equal 4, pending_data.size,
                 'should have 4 pending transactions'
  end

  test 'should fail safely' do
    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'
  end
end
