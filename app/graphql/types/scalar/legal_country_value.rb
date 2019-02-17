# frozen_string_literal: true

module Types
  module Scalar
    class LegalCountryValue < Types::Base::BaseScalar
      description <<~EOS
        This is just `CountryValue` but must be from a legal country
         Blocked countries:
        - Belarus
        - Cuba
        - Democratic Republic of the Congo
        - Iran
        - Iraq
        - Ivory Coast
        - Liberia
        - Myanmar
        - North Korea
        - South Sudan
        - United States
        - Zimbabwe
      EOS

      def self.coerce_input(input, _context)
        if Rails.configuration.countries
                .find_index do |country|
             country['value'] == input && country['blocked'] == false
           end.nil?
          raise GraphQL::CoercionError, "#{input.inspect} is not a valid or is a blocked country"
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
