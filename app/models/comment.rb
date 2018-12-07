# frozen_string_literal: true

require 'cancancan'

class Comment < ApplicationRecord
  attribute :replies

  COMMENT_MAX_DEPTH = Rails
                      .configuration
                      .proposals['comment_max_depth']
                      .to_i

  include StageField
  include Discard::Model
  has_closure_tree(order: 'created_at DESC')

  belongs_to :user
  has_many :comment_likes

  validates :body,
            presence: true,
            length: { maximum: 10_000 }
  validates :stage,
            presence: true
  validates :user,
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
    def comment(user, parent_comment, attrs)
      if parent_comment.depth >= COMMENT_MAX_DEPTH
        return [:maximum_comment_depth, nil]
      end

      unless (proposal = Proposal.find_by(comment_id: parent_comment.root.id))
        return %i[database_error comment_not_linked]
      end

      comment = Comment.new(
        body: attrs.fetch(:body, nil),
        stage: proposal.stage,
        parent: parent_comment,
        user: user
      )

      return [:invalid_data, comment.errors] unless comment.valid?
      return [:database_error, comment.errors] unless comment.save

      [:ok, comment]
    end

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

      return [:already_liked, nil] unless Ability.new(user).can?(:like, comment)

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

      return [:not_liked, nil] unless Ability.new(user).can?(:unlike, comment)

      ActiveRecord::Base.transaction do
        CommentLike.find_by(user_id: user.id, comment_id: comment.id).destroy!
        comment.update!(likes: comment.comment_likes.count)
      end

      [:ok, comment]
    end
  end
end
