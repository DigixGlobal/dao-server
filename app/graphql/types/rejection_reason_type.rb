# frozen_string_literal: true

module Types
  class RejectionReasonType < Types::BaseObject
    description 'Reasons for rejecting a KYC'

    field :value, String,
          null: false,
          description: 'Value of the reason'
    field :name, String,
          null: false,
          description: 'Descriptive name of the reason'
  end
end
