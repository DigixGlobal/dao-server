# frozen_string_literal: true

require 'cancancan'

module Resolvers
  class SearchDaoUsersResolver < Resolvers::Base
    type Types::User::DaoUserType.connection_type,
         null: false

    argument :term, String,
             required: true,
             description: <<~EOS
               Search by display name.

               If this starts with `user<uid>`, this will search by users with `uid`.
                Otherwise, it will search by username.

               Might be changed to a partial match or `LIKE` in the future.
             EOS

    def resolve(term:)
      source = User.order(created_at: :asc)

      if term.starts_with?('user')
        source.where(uid: term.sub('user', ''))
      else
        source.where(username: term)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:manage, User)
    end
  end
end
