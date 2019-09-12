# frozen_string_literal: true

module Types
  class MutationType < Types::Base::BaseObject
    field :change_email, mutation: Mutations::ChangeEmailMutation
    field :change_username, mutation: Mutations::ChangeUsernameMutation

    field :submit_kyc, mutation: Mutations::SubmitKycMutation
    field :approve_kyc, mutation: Mutations::ApproveKycMutation
    field :reject_kyc, mutation: Mutations::RejectKycMutation

    field :ban_user, mutation: Mutations::BanUserMutation
    field :unban_user, mutation: Mutations::UnbanUserMutation

    field :post_comment, mutation: Mutations::PostCommentMutation
    field :like_comment, mutation: Mutations::LikeCommentMutation
    field :unlike_comment, mutation: Mutations::UnlikeCommentMutation
    field :unpost_comment, mutation: Mutations::UnpostCommentMutation
    field :ban_comment, mutation: Mutations::BanCommentMutation
    field :unban_comment, mutation: Mutations::UnbanCommentMutation

    field :watch_transaction, mutation: Mutations::WatchTransactionMutation
    field :resend_transaction, mutation: Mutations::ResendTransactionMutation
  end
end
