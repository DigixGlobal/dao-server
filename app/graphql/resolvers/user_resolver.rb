# frozen_string_literal: true

require 'cancancan'

module Resolvers
  class UserResolver < Resolvers::Base
    type Types::User::AuthorizedUserType, null: true

    argument :id, String,
             required: true,
             description: 'Search user by their ID'

    def resolve(id:)
      User.find_by(id: id)
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:read, User)
    end
  end
end
