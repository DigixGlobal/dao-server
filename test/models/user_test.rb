# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'create new user should work' do
    params = attributes_for(:user)

    user = User.new(params)

    assert user.valid?,
           'should be valid'
    assert user.save,
           'should save'

    assert_not User.new(params).save,
               'should fail with the same data'
  end
end
