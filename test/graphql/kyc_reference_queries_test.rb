# frozen_string_literal: true

require 'test_helper'

class KycReferenceQueriesTest < ActiveSupport::TestCase
  COUNTRIES_QUERY = <<~EOS
    query {
      countries {
        value
        name
      }
    }
  EOS

  INCOME_RANGES_QUERY = <<~EOS
    query {
      incomeRanges {
        value
        range
      }
    }
  EOS

  INDUSTRIES_QUERY = <<~EOS
    query {
      industries {
        value
        name
      }
    }
  EOS

  test 'countries query should work' do
    result = DaoServerSchema.execute(
      COUNTRIES_QUERY,
      context: {},
      variables: {}
    )

    assert_nil result['errors'],
               'should have no errors'
    assert_not_empty result['data']['countries'],
                     'should work'
  end

  test 'income ranges query should work' do
    result = DaoServerSchema.execute(
      INCOME_RANGES_QUERY,
      context: {},
      variables: {}
    )

    assert_nil result['errors'],
               'should have no errors'
    assert_not_empty result['data']['incomeRanges'],
                     'should work'
  end

  test 'industries query should work' do
    result = DaoServerSchema.execute(
      INDUSTRIES_QUERY,
      context: {},
      variables: {}
    )

    assert_nil result['errors'],
               'should have no errors'
    assert_not_empty result['data']['industries'],
                     'should work'
  end
end
