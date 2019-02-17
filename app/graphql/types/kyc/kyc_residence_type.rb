# frozen_string_literal: true

module Types
  module Kyc
    class KycResidenceType < Types::Base::BaseObject
      description "Customer's KYC residence"

      field :address, String,
            null: false,
            description: 'Address of the residence'
      field :street, String,
            null: true,
            description: 'Street of the residence'
      field :city, String,
            null: false,
            description: 'City of the residence'
    end
  end
end
