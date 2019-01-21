# frozen_string_literal: true

module Types
  class IdentificationProofType < Types::BaseObject
    description 'Customer identification proof for KYC submission'

    field :identification_number, Types::Date,
          null: false,
          description: 'Designated code/number for the ID'
    field :expiration_date, Types::Date,
          null: false,
          description: 'Expiration date of the ID'
    field :image, Types::ImageType,
          null: false,
          description: 'Image of the ID'
  end
end
