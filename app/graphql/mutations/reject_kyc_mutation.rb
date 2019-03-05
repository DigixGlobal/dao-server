# frozen_string_literal: true

require 'cancancan'

module Mutations
  class RejectKycMutation < Types::Base::BaseMutation
    description <<~EOS
      As a KYC officer, reject a pending KYC with a reason.

      Role: KYC Officer
    EOS

    argument :kyc_id, String,
             required: true,
             description: 'The ID of the KYC'
    argument :rejection_reason, Types::Scalar::RejectionReasonValue,
             required: true,
             description: 'Reason for rejecting the KYC'

    field :kyc, Types::Kyc::KycType,
          null: true,
          description: 'Rejected KYC'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - KYC is not pending
          EOS

    def resolve(kyc_id:, rejection_reason:)
      officer = context.fetch(:current_user)

      key = :kyc

      unless (this_kyc = Kyc.kept.find_by(id: kyc_id))
        return form_error(key, 'kyc_id', 'KYC not found')
      end

      result, kyc_or_errors = Kyc.reject_kyc(officer, this_kyc, rejection_reason: rejection_reason)

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
        Ability.new(user).can?(:reject, Kyc)
    end
  end
end
