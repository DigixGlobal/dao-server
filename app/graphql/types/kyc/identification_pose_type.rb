# frozen_string_literal: true

module Types
  module Kyc
    class IdentificationPoseType < Types::Base::BaseObject
      description 'Customer ID pose for KYC submission'

      field :verification_code, String,
            null: false,
            description: 'Verification code for the pose'
      field :image, Types::ImageType,
            null: true,
            description: <<~EOS
              Image of the pose with the ID.
               It is possible for this to be `null` after submitting
              since file storage is asynchronous, so be careful with the mutation.
              Howver, it should be a valid object in practice.
            EOS
      end
  end
end
