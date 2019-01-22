# frozen_string_literal: true

module Resolvers
  class IncomeRangesResolver < Resolvers::Base
    type [Types::IncomeRangeType], null: false

    def resolve
      Rails.configuration.income_ranges
    end
  end
end
