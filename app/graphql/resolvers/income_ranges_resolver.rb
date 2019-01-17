# frozen_string_literal: true

module Resolvers
  class IncomeRangesResolver < Resolvers::Base
    type [Types::IncomeRangeType], null: false

    def resolve
      JSON.parse(File.read(File.join(Rails.root, 'config', 'income_ranges.json')))
    end
  end
end
