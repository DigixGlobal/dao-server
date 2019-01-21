# frozen_string_literal: true

module Types
  class ResidenceProofType < Types::BaseObject
    description 'Customer residence proof for KYC submission'

    field :address, Types::AddressType,
          null: false,
          description: 'Current residential address of the customer'
    field :type, Types::ResidenceProofTypeEnum,
          null: false,
          description: 'Kind of image presented as proof'
    field :image, Types::ImageType,
          null: false,
          description: 'Image of the ID'
  end
end
