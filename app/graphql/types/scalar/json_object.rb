# frozen_string_literal: true

module Types
  module Scalar
    class JSONObject < Types::Base::BaseScalar
      description <<~EOS
        The JSONified data object
      EOS

      def self.coerce_input(input, _context)
        data = JSON.parse(input)
        unless data.is_a?(Hash)
          raise GraphQL::CoercionError, "#{input.inspect} is not a JSON object"
        end

        data
      rescue JSON::ParserError
        raise GraphQL::CoercionError, "#{input.inspect} is not a valid JSON"
      end

      def self.coerce_result(value, _context)
        value
      end
    end
  end
end
