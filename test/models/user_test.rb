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

    assert_not user.update(address: 'g' + address.slice(2) + 'G'),
               'should only accept hexadecimal characters'
  end
end
