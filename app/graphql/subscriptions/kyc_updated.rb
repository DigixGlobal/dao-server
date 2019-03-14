# frozen_string_literal: true

module Subscriptions
  class KycUpdated < Subscriptions::BaseSubscription
    description 'Payload for any changes in a KYC'

    field :kyc, Types::Kyc::UpdatedKycType,
          null: false

    def subscribe
      :no_response
    end

    def update
      return :no_update unless object[:user_id] == context[:current_user_id]

      { kyc: object }
    end
  end
end
