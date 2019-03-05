# frozen_string_literal: true

module Types
  module Scalar
    class EthAddress < Types::Base::BaseScalar
      description <<~EOS
        The user's eth address represented by a `String`
      EOS

      def self.coerce_input(input, _context)
        if input && Eth::Utils.valid_address?(input)
          input
        else
          raise GraphQL::CoercionError, "#{input.inspect} is not a valid checksum address"
        end
      end

      def self.coerce_result(value, _context)
        value
      end
    end
  end
end
