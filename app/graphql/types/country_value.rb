# frozen_string_literal: true

module Types
  class CountryValue < Types::BaseScalar
    description <<~EOS
      A country represented by a string that comes form `Country.value`
    EOS

    def self.coerce_input(input, _context)
      countries = JSON.parse(File.read(File.join(Rails.root, 'config', 'countries.json')))

      if countries.find_index { |country| country['value'] == input }.nil?
        raise GraphQL::CoercionError, "#{input.inspect} is not a valid country"
      else
        input
      end
    end

    def self.coerce_result(value, _context)
      value
    end
  end
end
