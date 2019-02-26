# frozen_string_literal: true

module Types
  module Proposal
    class UpdatedCommentType < Types::Base::BaseObject
      description 'Update comment payload'

      field :id, ID,
            null: false,
            description: 'Comment ID'
      field :parent_id, String,
            null: false,
            description: 'Parent id of the comment'
      field :body, String,
            null: true,
            description: <<~EOS
              Message/body of the comment.
               This is `null` if this message is deleted or banned.
            EOS
      field :likes, Integer,
            null: false,
            description: 'Number of user who liked this comment'
    end
  end
end
