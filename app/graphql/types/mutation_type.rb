# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :change_email, mutation: Mutations::ChangeEmailMutation
    field :change_username, mutation: Mutations::ChangeUsernameMutation
    field :submit_kyc, mutation: Mutations::SubmitKycMutation
  end
end
