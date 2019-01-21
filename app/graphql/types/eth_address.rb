# frozen_string_literal: true

module Types
  class EthAddress < Types::BaseScalar
    description <<~EOS
      The user's eth address represented by a `String`
    EOS

    def self.coerce_input(input, _context)
      if value && Eth::Utils.valid_address?(value)
        value
      else
        raise GraphQL::CoercionError, "#{input.inspect} is not a valid checksum address"
      end
    end

    def self.coerce_result(value, _context)
      value
    end
  end
end
