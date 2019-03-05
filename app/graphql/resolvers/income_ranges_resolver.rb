# frozen_string_literal: true

module Resolvers
  class IncomeRangesResolver < Resolvers::Base
    type [Types::Value::IncomeRangeType], null: false

    def resolve
      Rails.configuration.income_ranges
    end
  end
end
