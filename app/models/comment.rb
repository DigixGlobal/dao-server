# frozen_string_literal: true

require 'cancancan'

class Comment < ApplicationRecord
  attribute :replies

  COMMENT_MAX_DEPTH = Rails
                      .configuration
                      .proposals['comment_max_depth']
                      .to_i

  DEPTH_LIMITS = [10, 5, 3].freeze

  include StageField
  include Discard::Model
  has_closure_tree

  belongs_to :user
  has_many :comment_likes

  validates :body,
            presence: true,
            length: { maximum: 10_000 }
  validates :stage,
            presence: true
  validates :user,
            presence: true

  def user_stage_comments(user, stage, criteria)
    last_seen_child_id = criteria.fetch(:last_seen_id, '').to_i
    sort_by = criteria.fetch(:sort_by, nil)

    comment_stage = stage || self.stage

    top_level =
      Comment
      .where(parent_id: id)
      .order(comment_sorting(self, sort_by))
      .joins(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(stage: comment_stage)
      .includes(:user, :comment_likes)
      .all
      .to_a

    child_levels =
      Comment
      .joins("INNER JOIN comment_hierarchies ON comments.id = comment_hierarchies.descendant_id AND comment_hierarchies.ancestor_id = #{id} AND comment_hierarchies.generations IN (2, 3)")
      .order('comments.created_at DESC')
      .joins(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(stage: comment_stage)
      .includes(:user, :comment_likes)
      .all
      .to_a

    comments = top_level.concat(child_levels)

    comment_trees = build_comment_trees(comments, self)
    after_comment_trees = comments_after_seen(comment_trees, last_seen_child_id)
    paginate_comment_trees(after_comment_trees, DEPTH_LIMITS)
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

  def comment_sorting(comment, sort_by)
    return 'comments.created_at DESC' if comment.depth == 1

    case sort_by
    when 'oldest'
      'comments.created_at ASC'
    else
      'comments.created_at DESC'
    end
  end

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

  def comments_after_seen(comments, last_seen_id)
    return [] if comments.empty?
    return comments unless last_seen_id

    unless (last_seen_index = comments.index { |comment| comment.id == last_seen_id })
      return comments
    end

    comments[(last_seen_index + 1)..-1]
  end

  def paginate_comment_trees(comment_trees, depth_limits)
    if comment_trees.empty? || depth_limits.empty?
      return DataWrapper.new(false, [])
    end

    depth_limit = depth_limits.first

    DataWrapper.new(
      comment_trees.size > depth_limit,
      comment_trees.take(depth_limit).map do |comment|
        comment.replies = paginate_comment_trees(comment.replies, depth_limits[1..-1])
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
