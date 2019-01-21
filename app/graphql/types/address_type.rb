# frozen_string_literal: true

module Types
  class AddressType < Types::BaseObject
    description 'Customer address for KYC submission'

    field :country, Types::CountryValue,
          null: false,
          description: 'Country of the address'
    field :address, String,
          null: false,
          description: 'Descriptive combination of unit/block/house number and street name of the address'
    field :address_details, String,
          null: true,
          description: 'Extra descriptions about the address such as landmarks or corners'
    field :city, String,
          null: false,
          description: 'City of the address'
    field :state, String,
          null: false,
          description: 'State division of the address'
    field :postal_code, String,
          null: false,
          description: 'Postal code of the address'
  end
end
