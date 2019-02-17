# frozen_string_literal: true

module Types
  class MutationType < Types::Base::BaseObject
    field :change_email, mutation: Mutations::ChangeEmailMutation
    field :change_username, mutation: Mutations::ChangeUsernameMutation
    field :submit_kyc, mutation: Mutations::SubmitKycMutation
    field :approve_kyc, mutation: Mutations::ApproveKycMutation
    field :reject_kyc, mutation: Mutations::RejectKycMutation
  end
end
