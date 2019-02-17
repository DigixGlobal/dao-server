# frozen_string_literal: true

module Mutations
  class ChangeEmailMutation < Types::Base::BaseMutation
    description "Change the current user's email"

    argument :email, String,
             required: true,
             description: <<~EOS
               New email for the user.

               Validations:
               - Maximum of 254 characters
               - Must be of this format: `<name_part>@<domain_part>`
             EOS

    field :user, Types::User::AuthorizedUserType,
          null: true,
          description: 'User with the updated email'
    field :errors, [UserErrorType],
          null: false,
          description: 'Mutation errors'

    def resolve(email:)
      user = context.fetch(:current_user)
      this_user = User.find(user.id)

      result, user_or_errors = User.change_email(this_user, email)

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
  end
end
