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

  test 'user address should validate correctly' do
    user = create(:user)
    address = generate(:address)

    assert user.update(address: address),
           'should be valid'
    assert user.update(address: address.upcase.sub('X', 'x')),
           'should be case insensitive'

    assert_not user.update(address: ''),
               'should not accept empty'

    assert_not user.update(address: address + 'a'),
               'should not exceed 42 characters'
    assert_not user.update(address: address.slice(1)),
               'should not fall below 42 characters'

    assert_not user.update(address: "0xg#{address.slice(4)}G"),
               'should only accept hexadecimal characters'
  end

  test 'change username should work' do
    user = create(:user)
    username = generate(:username).upcase

    ok, user = User.change_username(user, username)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of User, user,
                   'result should be a user'
    assert_equal username.downcase, user.username.downcase,
                 'username should be changed and downcased'

    another_username = generate(:username)

    username_already_set, = User.change_username(user, another_username)

    assert_equal :username_already_set, username_already_set,
                 'should not allow username to be changed again'

    other_user = create(:user)
    starting_with_username = "user#{generate(:username)}"

    invalid_data, = User.change_username(other_user, starting_with_username)

    assert_equal :invalid_data, invalid_data,
                 'should fail if it starts with `user`'

    invalid_data, = User.change_username(other_user, '')

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty username'
  end

  test 'change email should work' do
    user = create(:user)
    email = generate(:email)

    ok, updated_user = User.change_email(user, email)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of User, updated_user,
                   'result should be a user'
    assert_equal email, updated_user.email,
                 'email should be the changed'

    another_email = generate(:email)

    ok, = User.change_email(updated_user, another_email)

    assert_equal :ok, ok,
                 'should allow multiple changes'

    invalid_data, = User.change_email(create(:user), '')

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty email'
  end
end
