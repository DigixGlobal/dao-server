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
      kyc = object[:kyc]

      return :no_update unless kyc[:user_id] == context[:current_user_id]

      { kyc: kyc }
    end
  end
end
