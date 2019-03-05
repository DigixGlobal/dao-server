# frozen_string_literal: true

module Types
  module Scalar
    class DataUrl < Types::Base::BaseScalar
      description <<~EOS
        A base64-encoded data URL (`data:image/png;base64;...`)
        represented as a object with data and file type but no filename
      EOS

      def self.coerce_input(input, _context)
        URI::Data.new(input)
      rescue URI::InvalidURIError
        raise GraphQL::CoercionError,
              "#{input.inspect} is not a valid data URI"
      end

      def self.coerce_result(value, _context)
        value.to_s
      end
    end
  end
end
