# frozen_string_literal: true

module Types
  module Scalar
    class IncomeRangeValue < Types::Base::BaseScalar
      description <<~EOS
        Income ranges represented by a string that comes form `IncomeRange.value`
      EOS

      def self.coerce_input(input, _context)
        if Rails.configuration.income_ranges
                .find_index { |range| range['value'] == input }.nil?
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
end
