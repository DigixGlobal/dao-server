# frozen_string_literal: true

require 'cancancan'

class Comment < ApplicationRecord
  attribute :comment_like_id
  attribute :replies
  attribute :liked

  COMMENT_MAX_DEPTH = Rails
                      .configuration
                      .proposals['comment_max_depth']
                      .to_i

  DEPTH_LIMITS = Rails
                 .configuration
                 .comments['depth_limits']

  SORTING_OPTIONS = %i[latest oldest].freeze

  include StageField
  include Discard::Model
  has_closure_tree(order: 'created_at ASC')

  belongs_to :user
  has_many :comment_likes

  validates :body,
            presence: true,
            length: { maximum: 10_000 }
  validates :stage,
            presence: true
  validates :user,
            presence: true

  def query_user_proposal_threads(user, criteria)
    comment_stage = criteria.fetch(:stage, stage)
    sort_by = criteria.fetch(:sort_by, nil)

    Comment
      .preload(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(stage: comment_stage, parent_id: id)
      .select(
        'comment_likes.id AS liked',
        :id,
        :user_id,
        :parent_id,
        :body,
        :likes,
        :stage,
        :user_id,
        :created_at,
        :updated_at,
        :discarded_at
      )
      .order(comment_sorting(self, sort_by))
  end

  def user_stage_comments(user, stage, criteria)
    last_seen_child_id = criteria.fetch(:last_seen_id, '').to_i
    sort_by = criteria.fetch(:sort_by, nil)

    comment_stage = stage || self.stage

    top_level =
      Comment
      .preload(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(stage: comment_stage, parent_id: id)
      .select('comment_likes.id AS comment_like_id', :id, :user_id, :parent_id, :body, :likes, :stage, :user_id, :created_at, :updated_at, :discarded_at)
      .order(comment_sorting(self, sort_by))
      .to_a

    child_levels =
      Comment
      .preload(:user)
      .joins("INNER JOIN comment_hierarchies ON comments.id = comment_hierarchies.descendant_id AND comment_hierarchies.ancestor_id = #{id} AND comment_hierarchies.generations IN (2, 3, 4)")
      .includes(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(stage: comment_stage)
      .select('comment_likes.id AS comment_like_id', :id, :user_id, :parent_id, :body, :likes, :stage, :user_id, :created_at, :updated_at, :discarded_at)
      .order('comments.created_at ASC')
      .to_a

    comments = top_level.concat(child_levels)

    comment_trees = build_comment_trees(comments, self)
    after_comment_trees = comments_after_seen(comment_trees, last_seen_child_id)
    paginate_comment_trees(after_comment_trees, DEPTH_LIMITS)
  end

  def as_json(options = {})
    base_hash = serializable_hash(
      except: %i[body replies parent_id discarded_at],
      include: { user: { only: :address } }
    )

    user_comment_like_id = base_hash.delete 'comment_like_id'

    base_hash.merge(
      'body' => discarded? ? nil : body,
      'replies' => replies&.as_json || DataWrapper.new(false, []),
      'liked' => !user_comment_like_id.nil?
    ).deep_transform_keys! { |key| key.camelize(:lower) }
  end

  def user_like(user)
    CommentLike.find_by(comment_id: id, user_id: user.id)
  end

  private

  def comment_sorting(comment, sort_by)
    return 'comments.created_at ASC' if comment.depth > 0

    case sort_by
    when :latest, 'latest'
      'comments.created_at DESC'
    else
      'comments.created_at ASC'
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
    return DataWrapper.new(false, []) if comment_trees.empty?
    return DataWrapper.new(!comment_trees.empty?, []) if depth_limits.empty?

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
