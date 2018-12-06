# frozen_string_literal: true

require 'cancancan'

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

  def user_like(user)
    CommentLike.find_by(comment_id: id, user_id: user.id)
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
      unless (comment = Comment.find_by(id: comment.id))
        return [:comment_not_found, nil]
      end

      unless Ability.new(user).can?(:like, comment)
        return [:already_liked, nil]
      end

      ActiveRecord::Base.transaction do
        CommentLike.new(user_id: user.id, comment_id: comment.id).save!
        comment.update!(likes: comment.comment_likes.count)
      end

      [:ok, comment]
    end

    def unlike(user, comment)
      unless (comment = Comment.find_by(id: comment.id))
        return [:comment_not_found, nil]
      end

      unless Ability.new(user).can?(:unlike, comment)
        return [:not_liked, nil]
      end

      ActiveRecord::Base.transaction do
        CommentLike.find_by(user_id: user.id, comment_id: comment.id).destroy!
        comment.update!(likes: comment.comment_likes.count)
      end

      [:ok, comment]
    end
  end
end
