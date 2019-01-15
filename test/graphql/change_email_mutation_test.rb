# frozen_string_literal: true

require 'test_helper'

class ChangeEmailMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($email: String!) {
      changeEmail(input: {email: $email}) {
        user {
          email
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'change email mutation should work' do
    user = create(:user)
    email = generate(:email)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { email: email }
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['changeEmail']['errors'],
                 'should have no errors'

    assert_equal email, result['data']['changeEmail']['user']['email'],
                 'email should be updated'
  end

  test 'should fail safely' do
    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: { email: '' }
    )

    assert_not_empty empty_result['data']['changeEmail']['errors'],
                     'should fail on empty data'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'
  end
end
