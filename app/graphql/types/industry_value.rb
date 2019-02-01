# frozen_string_literal: true

module Types
  class IndustryValue < Types::BaseScalar
    description <<~EOS
      Industry for KYC submission
    EOS

    def self.coerce_input(input, _context)
      if Rails.configuration.industries
              .find_index { |range| range['value'] == input }.nil?
        raise GraphQL::CoercionError, "#{input.inspect} is not a valid industry"
      else
        input
      end
    end

    def self.coerce_result(value, _context)
      value
    end
  end
end
