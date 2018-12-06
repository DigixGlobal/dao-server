# frozen_string_literal: true

class CommentLike < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  validates :user,
            presence: true
  validates :comment,
            presence: true
  validates_uniqueness_of :user_id,
                          scope: :comment_id
end
