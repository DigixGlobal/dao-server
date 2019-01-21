# frozen_string_literal: true

require 'test_helper'

class ScalarTest < ActiveSupport::TestCase
  test 'country scalar should work' do
    countries = JSON.parse(File.read(File.join(Rails.root, 'config', 'countries.json')))

    countries
      .sample(10)
      .each do |country|
      value = country['value']
      assert_equal value, Types::CountryValue.coerce_input(value, nil),
                   'country should work'
      begin
        Types::CountryValue.coerce_input(value + '!', nil)
        flunk 'country should fail on invalid range'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end

  test 'income range scalar should work' do
    income_ranges = JSON.parse(File.read(File.join(Rails.root, 'config', 'income_ranges.json')))

    income_ranges
      .each do |income_range|
      value = income_range['value']
      assert_equal value, Types::IncomeRangeValue.coerce_input(value, nil),
                   'income range should work'
      begin
        Types::IncomeRangeValue.coerce_input(value + '!', nil)
        flunk 'income range should fail on invalid value'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end

  test 'industry scalar should work' do
    industries = JSON.parse(File.read(File.join(Rails.root, 'config', 'industries.json')))

    industries
      .each do |industry|
      value = industry['value']
      assert_equal value, Types::IndustryValue.coerce_input(value, nil),
                   'industry should work'
      begin
        Types::IndustryValue.coerce_input(value + '!', nil)
        flunk 'industry should fail on invalid value'
      rescue GraphQL::CoercionError
        # Exception should be raised
      end
    end
  end
end
