# frozen_string_literal: true

module Types
  class PositiveInteger < Types::BaseScalar
    description <<~EOS
      A positive integer taken from the `Integer` implementation
    EOS

    def self.coerce_input(value, _context)
      unless value.is_a?(Numeric) && (int = value.to_i) > 0
        raise GraphQL::CoercionError, "#{value} is not a positive integer"
      end

      int
    end

    def self.coerce_result(value, _context)
      value.to_i
    end
  end
end
