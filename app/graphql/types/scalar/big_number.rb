# frozen_string_literal: true

module Types
  module Scalar
    class BigNumber < Types::Base::BaseScalar
      description <<~EOS
        A decimal value represented as a `String`
      EOS

      def self.coerce_input(input, _context)
        input
      end

      def self.coerce_result(value, _context)
        value
      end
    end
  end
end
