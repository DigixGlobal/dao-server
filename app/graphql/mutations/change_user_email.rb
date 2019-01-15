# frozen_string_literal: true

module Mutations
  class ChangeUserEmail < Types::BaseMutation
    description "Change the current user's email"

    argument :email, String,
             required: true,
             description: 'New email for the user'

    field :user, Types::UserType,
          null: true,
          description: 'User with the updated email'
    field :errors, [UserErrorType],
          null: false,
          description: 'Mutation errors'

    def resolve(email:)
      user = context.fetch(:current_user)

      result, user_or_errors = User.change_email(user, email)

      key = :user

      case result
      when :invalid_data
        model_errors(user_or_errors, key)
      when :ok
        model_result(user_or_errors, key)
      end
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end

    def self.visible?(context)
      authorized?(nil, context)
    end
  end
end
