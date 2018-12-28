# frozen_string_literal: true

module Types
  module LikeableType
    include Types::BaseInterface
    description 'Something that can be liked.'

    field :likes, Integer,
          null: false,
          description: 'Number of user likes for this'
    field :liked, Boolean,
          null: false,
          description: 'A flag to indicate if the current user liked this'
  end
end
