# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :change_email, mutation: Mutations::ChangeEmail
    field :change_username, mutation: Mutations::ChangeUsername
  end
end
