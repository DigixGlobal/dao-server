# frozen_string_literal: true

require 'test_helper'

class AppUserQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query {
      appUser {
        isUnavailable
        isUnderMaintenance
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

    empty_ip_result = DaoServerSchema.execute(
      QUERY,
      context: { ip_address: '' },
      variables: {}
    )

    assert_not_empty empty_ip_result['data']['appUser'],
                     'should work even without ip address user'
  end

  test 'isUnavailable country ips should work' do
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

  test 'isUnavailable whitelist ips should work' do
    valid_ip = '1.208.104.202'
    invalid_ip = '23.31.255.254'

    valid_result = DaoServerSchema.execute(
      QUERY,
      context: { ip_address: valid_ip },
      variables: {}
    )

    refute valid_result['data']['appUser']['isUnavailable'],
           'valid ip should be available'

    invalid_result = DaoServerSchema.execute(
      QUERY,
      context: { ip_address: invalid_ip },
      variables: {}
    )

    assert invalid_result['data']['appUser']['isUnavailable'],
           'invalid ip should be unavailable'

    ['23.31.255.253',
     '96.69.193.162',
     '96.69.193.160',
     '96.69.193.167'].each do |invalid_whitelisted_ip|
      whitelisted_result = DaoServerSchema.execute(
        QUERY,
        context: { ip_address: invalid_whitelisted_ip },
        variables: {}
      )

      refute whitelisted_result['data']['appUser']['isUnavailable'],
             'invalid ip that is whitelisted should be available'
    end

    ['96.69.193.159',
     '96.69.193.168'].each do |outside_whitelisted_ip|
      outside_result = DaoServerSchema.execute(
        QUERY,
        context: { ip_address: outside_whitelisted_ip },
        variables: {}
      )

      assert outside_result['data']['appUser']['isUnavailable'],
             'invalid ip that is outside the whitelist ranges should be unavailable'
    end
  end

  test 'isUnderMaintenance should work' do
    default_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    refute default_result['data']['appUser']['isUnderMaintenance'],
           'isUnderMaintenance should be false by default'

    ENV['IS_UNDER_MAINTENANCE'] = 'true'

    set_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert set_result['data']['appUser']['isUnderMaintenance'],
           'isUnderMaintenance should be true when set:'
  end
end
