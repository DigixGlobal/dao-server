# frozen_string_literal: true

require 'cancancan'

module Mutations
  class ApproveKycMutation < Types::Base::BaseMutation
    description <<~EOS
      As a KYC officer, approve a pending KYC.

      Role: KYC Officer
    EOS

    argument :kyc_id, String,
             required: true,
             description: 'The ID of the KYC'
    argument :expiration_date, Types::Scalar::Date,
             required: true,
             description: <<~EOS
               Expiration date for this KYC.

               Validations:
               - Must be a future date.
             EOS

    field :kyc, Types::Kyc::KycType,
          null: true,
          description: 'Approved KYC'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - KYC is not pending
            - KYC not found
          EOS

    def resolve(kyc_id:, expiration_date:)
      officer = context.fetch(:current_user)

      key = :kyc

      unless (this_kyc = Kyc.kept.find_by(id: kyc_id))
        return form_error(key, 'kyc_id', 'KYC not found')
      end

      result, kyc_or_errors = Kyc.approve_kyc(officer, this_kyc, expiration_date: expiration_date)

      case result
      when :kyc_not_pending, :unauthorized_action
        form_error(key, '_', 'KYC is not pending')
      when :invalid_data
        model_errors(key, kyc_or_errors)
      when :ok
        model_result(key, kyc_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:approve, Kyc)
    end
  end
end
