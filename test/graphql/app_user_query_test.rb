# frozen_string_literal: true

require 'test_helper'

class AppUserQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query {
      appUser {
        isUnavailable
      }
    }
  EOS

  test 'app user should work' do
    result = DaoServerSchema.execute(
      QUERY,
      context: { ip_address: nil },
      variables: {}
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['appUser']

    assert_not_empty data,
                     'app user type should work'
    refute data['isUnavailable'],
           'isUnavailable should default to false'

    [
      '10.0.0.0',
      '172.16.0.0',
      '192.168.0.0',
      '224.0.0.0',
      '0.0.0.0',
      '127.0.0.0'
    ].each do |ip|
      special_result = DaoServerSchema.execute(
        QUERY,
        context: { ip_address: ip },
        variables: {}
      )

      special_data = special_result['data']['appUser']

      refute special_data['isUnavailable'],
             'isUnavailable should work with special ip addresses'
    end

    [ # Asia
      '1.208.104.201',
      # EU
      '2.16.19.255'
    ].each do |ip|
      available_result = DaoServerSchema.execute(
        QUERY,
        context: { ip_address: ip },
        variables: {}
      )

      available_data = available_result['data']['appUser']

      refute available_data['isUnavailable'],
             'isUnavailable should be false with available countries'
    end

    [ # US
      '1.32.239.255',
      '4.1.13.100',
      '23.31.255.255'
    ].each do |ip|
      unavailable_result = DaoServerSchema.execute(
        QUERY,
        context: { ip_address: ip },
        variables: {}
      )

      unavailable_data = unavailable_result['data']['appUser']

      assert unavailable_data['isUnavailable'],
             'isUnavailable should be true with unavailable countries'
    end
  end
end
