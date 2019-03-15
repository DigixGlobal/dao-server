# frozen_string_literal: true

module Types
  module Kyc
    class UpdatedKycType < Types::Base::BaseObject
      description 'Changes in KYC'

      field :id, ID,
            null: false,
            description: 'KYC ID'
      field :status, Types::Enum::KycStatusEnum,
            null: false,
            description: <<~EOS
              Current status or state of the KYC.
               If the KYC is approved and it is after the expiration date,
               the status is expired.
            EOS
    end
  end
end
