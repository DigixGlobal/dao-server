# frozen_string_literal: true

module Types
  module Value
    class CountryType < Types::Base::BaseObject
      description 'Country for KYC Registration'

      field :value, String,
            null: false,
            description: 'App value of the country'
      field :name, String,
            null: false,
            description: 'Name of the country'
      field :blocked, Boolean,
            null: false,
            description: 'A flag if the country is blocked'
    end
  end
end
