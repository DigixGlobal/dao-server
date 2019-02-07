# frozen_string_literal: true

require 'test_helper'

class ScalarTest < ActiveSupport::TestCase
  test 'country scalar should work' do
    Rails.configuration.countries
         .sample(10)
         .each do |country|
      value = country['value']
      assert_equal value, Types::Scalar::CountryValue.coerce_input(value, nil),
                   'country should work'
      begin
        Types::Scalar::CountryValue.coerce_input(value + '!', nil)
        flunk 'country should fail on invalid range'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end

  test 'income range scalar should work' do
    Rails.configuration.income_ranges
         .each do |income_range|
      value = income_range['value']
      assert_equal value, Types::Scalar::IncomeRangeValue.coerce_input(value, nil),
                   'income range should work'
      begin
        Types::Scalar::IncomeRangeValue.coerce_input(value + '!', nil)
        flunk 'income range should fail on invalid value'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end

  test 'industry scalar should work' do
    Rails.configuration.industries
         .each do |industry|
      value = industry['value']
      assert_equal value, Types::Scalar::IndustryValue.coerce_input(value, nil),
                   'industry should work'
      begin
        Types::Scalar::IndustryValue.coerce_input(value + '!', nil)
        flunk 'industry should fail on invalid value'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end

  test 'rejection reason scalar should work' do
    reasons = JSON.parse(File.read(File.join(Rails.root, 'config', 'rejection_reasons.json')))

    reasons
      .each do |reason|
      value = reason['value']
      assert_equal value, Types::Scalar::RejectionReasonValue.coerce_input(value, nil),
                   'rejection reason should work'
      begin
        Types::Scalar::RejectionReasonValue.coerce_input(value + '!', nil)
        flunk 'rejection reason should fail on invalid value'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end
end
