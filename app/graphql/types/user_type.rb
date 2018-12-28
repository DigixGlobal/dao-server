# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    description 'DAO users who publish proposals and vote for them'

    field :id, ID,
          null: false,
          description: 'User ID'
    field :address, String,
          null: false,
          description: 'Eth address of the user '

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end

    def self.visible?(context)
      authorized?(nil, context)
    end
  end
end
