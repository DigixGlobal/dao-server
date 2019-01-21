# frozen_string_literal: true

module Types
  class Date < Types::BaseScalar
    description <<~EOS
      A date represented as a YYYY-MM-DD or iso8601 date
    EOS

    def self.coerce_input(input, _context)
      Date.iso8601(input)
    rescue ArgumentError
      raise GraphQL::CoercionError,
            "#{input.inspect} is not a valid ISO8601 date"
    end

    def self.coerce_result(value, _context)
      value.strftime('%F')
    end
  end
end
