# frozen_string_literal: true

require 'cancancan'

class Comment < ApplicationRecord
  attribute :replies

  COMMENT_MAX_DEPTH = Rails
                      .configuration
                      .proposals['comment_max_depth']
                      .to_i

  FUDGE_FACTOR = 2
  FIRST_LEVEL_LIMIT = 10
  SECOND_LEVEL_LIMIT = 5
  THIRD_LEVEL_LIMIT = 3

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

  def user_stage_comments(user, stage)
    comment_scope = self

    first_level = comment_scope
                  .find_all_by_generation(1)
                  .limit(FUDGE_FACTOR * FIRST_LEVEL_LIMIT)

    second_level = comment_scope
                   .find_all_by_generation(2)
                   .limit(FUDGE_FACTOR * FIRST_LEVEL_LIMIT * SECOND_LEVEL_LIMIT)

    third_level = comment_scope
                  .find_all_by_generation(3)
                  .limit(FUDGE_FACTOR * FIRST_LEVEL_LIMIT * SECOND_LEVEL_LIMIT * THIRD_LEVEL_LIMIT)

    comments = first_level.union(second_level).union(third_level).all.to_a
    comment_trees = build_comment_trees(comments, self)
    paginate_comment_trees(comment_trees, 1)
  end

  def y
    x
      .joins(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(stage: stage)
      .includes(:user)
  end

  def as_json(options = {})
    base_hash = serializable_hash(
      except: %i[body replies parent_id discarded_at],
      include: { user: { only: :address }, comment_likes: {} }
    )

    user_likes = base_hash.delete 'comment_likes'

    base_hash.merge(
      'body' => discarded? ? nil : body,
      'replies' => replies&.as_json,
      'liked' => !user_likes.empty?
    ).deep_transform_keys! { |key| key.camelize(:lower) }
  end

  def user_like(user)
    CommentLike.find_by(comment_id: id, user_id: user.id)
  end

  private

  def build_comment_trees(comments, root_comment)
    return [] if comments.empty?

    comment_map = {}

    comments.each do |comment|
      comment_map[comment.id] = comment
      comment.replies = []
    end

    comments
      .reject { |comment| comment.parent_id == root_comment.id }
      .each do |comment|
        if (parent_comment = comment_map.fetch(comment.parent_id, nil))
          parent_comment.replies.push(comment)
        end
      end

    comments.select { |comment| comment.parent_id == root_comment.id }
  end

  def paginate_comment_trees(comment_trees, depth)
    return DataWrapper.new(false, []) if comment_trees.empty?

    depth_limit =
      case depth
      when 1
        FIRST_LEVEL_LIMIT
      when 2
        SECOND_LEVEL_LIMIT
      when 3
        THIRD_LEVEL_LIMIT
      else
        3
      end

    DataWrapper.new(
      comment_trees.size > depth_limit,
      comment_trees.take(depth_limit).map do |comment|
        comment.replies = paginate_comment_trees(comment.replies, depth + 1)
        comment
      end
    )
  end

  class DataWrapper
    include ActiveModel::Serialization

    attr_accessor :has_more, :data

    def initialize(has_more, data)
      self.has_more = has_more
      self.data = data
    end

    def attributes
      { 'has_more' => false, 'data' => [] }
    end

    def as_json(options = {})
      {
        'hasMore' => has_more,
        'data' => data.map { |item| item.as_json(options) }
      }
    end
  end

  class << self
    def comment(user, parent_comment, attrs)
      if parent_comment.depth >= COMMENT_MAX_DEPTH
        return [:maximum_comment_depth, nil]
      end

      unless Ability.new(user).can?(:comment, parent_comment)
        return [:action_invalid, nil]
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
      return [:already_liked, nil] unless Ability.new(user).can?(:like, comment)

      ActiveRecord::Base.transaction do
        CommentLike.new(user_id: user.id, comment_id: comment.id).save!
        comment.update!(likes: comment.comment_likes.count)
      end

      [:ok, comment]
    end

    def unlike(user, comment)
      return [:not_liked, nil] unless Ability.new(user).can?(:unlike, comment)

      ActiveRecord::Base.transaction do
        CommentLike.find_by(user_id: user.id, comment_id: comment.id).destroy!
        comment.update!(likes: comment.comment_likes.count)
      end

      [:ok, comment]
    end
  end
end
