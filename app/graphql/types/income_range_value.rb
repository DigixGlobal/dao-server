# frozen_string_literal: true

module Types
  class IncomeRangeValue < Types::BaseScalar
    description <<~EOS
      Income ranges represented by a string that comes form `IncomeRange.value`
    EOS

    def self.coerce_input(input, _context)
      income_ranges = JSON.parse(File.read(File.join(Rails.root, 'config', 'income_ranges.json')))

      if income_ranges.find_index { |range| range['value'] == input }.nil?
        raise GraphQL::CoercionError, "#{input.inspect} is not a valid income range"
      else
        input
      end
    end

    def self.coerce_result(value, _context)
      value
    end
  end
end
