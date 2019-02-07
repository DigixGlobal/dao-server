# frozen_string_literal: true

module Types
  class IdentificationProofType < Types::BaseObject
    description 'Customer identification proof for KYC submission'

    field :number, String,
          null: false,
          description: 'Designated code/number for the ID'
    field :type, Types::IdentificationProofTypeEnum,
          null: false,
          description: 'Type of ID used'
    field :expiration_date, Types::Date,
          null: false,
          description: 'Expiration date of the ID'
    field :image, Types::ImageType,
          null: true,
          description: <<~EOS
            Image of the ID.

            It is possible for this to be `null` after submitting
            since file storage is asynchronous, so be careful with the mutation.
            Howver, it should be a valid object in practice.
          EOS
  end
end
