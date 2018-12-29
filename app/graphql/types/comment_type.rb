# frozen_string_literal: true

module Types
  class CommentType < Types::BaseObject
    description 'Comments/messages between voters for proposals'

    field :id, ID,
          null: false,
          description: 'Comment ID'
    field :stage, StageType,
          null: false,
          description: 'Stage/phase the comment was published'
    field :body, String,
          null: true,
          description: <<~EOS
            Message/body of the comment.

            This is `null` if this message is deleted.
          EOS

    field :likes, Integer,
          null: false,
          description: 'Number of user who liked this comment'
    field :liked, Boolean,
          null: false,
          description: 'A flag to indicate if the current user liked this comment'

    field :created_at, GraphQL::Types::ISO8601DateTime,
          null: false,
          description: 'Date when the comment was published'

    field :user, UserType,
          null: false,
          description: 'Poster of this comment'
    field :replies, [CommentType],
          null: false,
          description: 'Replies/comments about this comment'

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end

    def self.visible?(context)
      authorized?(nil, context)
    end
  end
end
