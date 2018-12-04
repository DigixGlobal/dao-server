# frozen_string_literal: true

class Comment < ApplicationRecord
  attribute :replies

  include StageField
  include Discard::Model
  has_closure_tree(order: 'created_at DESC')

  belongs_to :user
  belongs_to :proposal
  has_many :comment_likes

  validates :body,
            presence: true,
            length: { maximum: 10_000 }
  validates :stage,
            presence: true
  validates :user,
            presence: true
  validates :proposal,
            presence: true

  def as_json(options = {})
    base_hash = serializable_hash(
      except: %i[body replies parent_id discarded_at],
      include: { user: { only: :address }, comment_likes: {} }
    )

    user_likes = base_hash.delete 'comment_likes'

    base_hash.merge(
      'body' => discarded? ? nil : body,
      'replies' => replies&.map { |reply| reply.as_json(options) },
      'liked' => !user_likes.empty?
    ).deep_transform_keys! { |key| key.camelize(:lower) }
  end

  class << self
    def delete(user, comment)
      return [:already_deleted, nil] if comment.discarded?

      unless Ability.new(user).can?(:delete, comment)
        return [:unauthorized_action, nil]
      end

      comment.discard

      [:ok, comment]
    end

    def like(user, comment)
      attrs = { user_id: user.id, comment_id: comment.id }

      return [:already_liked, nil] if CommentLike.find_by(attrs)

      result = nil

      ActiveRecord::Base.transaction do
        CommentLike.new(attrs).save!
        comment.update!(likes: comment.comment_likes.count)

        result = [:ok, comment]
      end

      result
    end

    def unlike(user, comment)
      attrs = { user_id: user.id, comment_id: comment.id }

      return [:not_liked, nil] unless (like = CommentLike.find_by(attrs))

      result = nil

      ActiveRecord::Base.transaction do
        like.destroy!
        comment.update!(likes: comment.comment_likes.count)

        result = [:ok, comment]
      end

      result
    end
  end
end
