# frozen_string_literal: true

require 'test_helper'

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test 'connect should work' do
      user = create(:user)

      connect params: user.create_new_auth_token

      assert_equal user, connection.current_user,
                   'connection should have the current user'
    end

    test 'should fail safely' do
      assert_reject_connection do
        connect params: {}
      end

      user = create(:user)

      assert_reject_connection do
        connect params: { 'access-token' => '', 'client' => '', 'uid' => user.uid }
      end
    end
  end
end
