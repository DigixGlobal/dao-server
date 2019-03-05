# frozen_string_literal: true

module Types
  module Value
    class RejectionReasonType < Types::Base::BaseObject
      description 'Reasons for rejecting a KYC'

      field :value, String,
            null: false,
            description: 'Value of the reason'
      field :name, String,
            null: false,
            description: 'Descriptive name of the reason'
    end
  end
end
