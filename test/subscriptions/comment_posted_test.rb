# frozen_string_literal: true

require 'test_helper'

class CommentPostedTest < ActionCable::Channel::TestCase
  tests GraphqlChannel

  QUERY = <<~EOS
    subscription {
      commentPosted {
        comment {
          id
          body
          likes
          liked
        }
      }
    }
  EOS

  test 'should work' do
    stub_connection(current_user: create(:user))
    subscribe

    assert_broadcasts 'commentPosted', 0

    perform :execute,
            query: QUERY,
            variables: {}

    DaoServerSchema.subscriptions.trigger('commentPosted', {}, { comment: create(:comment) }, {})

    # No possible test yet
  end
end
