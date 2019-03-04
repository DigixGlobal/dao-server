# frozen_string_literal: true

require 'test_helper'

class SearchDaoQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($term: String!) {
      searchDaoUsers(term: $term) {
        edges {
          node {
            id
            canComment
            isBanned
          }
        }
      }
    }
  EOS

  test 'search dao users should work' do
    admin = create(:forum_admin_user)

    users = create_list(:user_with_username, 6)

    username_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: admin },
      variables: { term: users.pluck(:username).sample }
    )

    assert_nil username_result['errors'],
               'should work with username term and have no errors'
    assert_not_empty username_result['data']['searchDaoUsers'],
                     'should have at data'

    uid_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: admin },
      variables: { term: "user#{users.pluck(:uid).sample}" }
    )

    assert_nil uid_result['errors'],
               'should work with uid term and have no errors'
    assert_not_empty uid_result['data']['searchDaoUsers'],
                     'should have at data'

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: admin },
      variables: { term: '' }
    )

    assert_empty empty_result['data']['searchDaoUsers']['edges'],
                 'should have no data'
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
