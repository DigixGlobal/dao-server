# frozen_string_literal: true

module Types
  module Scalar
    class RejectionReasonValue < Types::Base::BaseScalar
      description <<~EOS
        A rejection rason represented by a string that comes form `RejectionReason.value`
      EOS

      def self.coerce_input(input, _context)
        reasons = JSON.parse(File.read(File.join(Rails.root, 'config', 'rejection_reasons.json')))

        if reasons.find_index { |reason| reason['value'] == input }.nil?
          raise GraphQL::CoercionError, "#{input.inspect} is not a valid rejection reason"
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
