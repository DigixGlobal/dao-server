# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :change_user_email, mutation: Mutations::ChangeUserEmail
    field :change_user_username, mutation: Mutations::ChangeUserUsername
  end
end
