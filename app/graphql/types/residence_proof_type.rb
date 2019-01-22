# frozen_string_literal: true

module Types
  class ResidenceProofType < Types::BaseObject
    description 'Customer residence proof for KYC submission'

    field :residence, Types::AddressType,
          null: false,
          description: 'Current residential address of the customer'
    field :type, Types::ResidenceProofTypeEnum,
          null: false,
          description: 'Kind of image presented as proof'
    field :image, Types::ImageType,
          null: true,
          description: <<~EOS
            Image of the residence proof.

            It is possible for this to be `null` after submitting
            since file storage is asynchronous, so be careful with the mutation.
            Howver, it should be a valid object in practice.
          EOS
  end
end
