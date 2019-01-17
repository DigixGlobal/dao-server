# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    description 'DAO users who publish proposals and vote for them'

    field :display_name, String,
          null: false,
          description: <<~EOS
            Display name of the user which should be used to identify the user.

            This is just username if it is set; otherwise, this is just `user<id>`.
          EOS

    def display_name
      object['username'].nil? ? "user#{object['id']}" : object['username']
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end
  end
end
