# frozen_string_literal: true

class Proposal < ApplicationRecord
  include StageField

  COMMENT_MAX_DEPTH = Rails
                      .configuration
                      .proposals['comment_max_depth']
                      .to_i

  belongs_to :user
  has_many :comments, -> { where(parent_id: nil) }
  has_many :proposal_likes

  validates :stage,
            presence: true
  validates :user,
            presence: true,
            uniqueness: true

  def user_threads(user)
    Comment
      .joins(:user)
      .joins("LEFT OUTER JOIN comment_likes ON comment_likes.comment_id = comments.id AND comment_likes.user_id = #{user.id}")
      .where(proposal_id: id)
      .order(created_at: :desc)
      .includes(%i[user])
      .group_by(&:stage)
      .map do |key, stage_comments|
      [
        key,
        build_comment_trees(stage_comments)
      ]
    end
      .to_h
  end

  private

  def build_comment_trees(comments)
    return [] if comments.empty?

    comment_map = {}

    comments.each do |comment|
      comment_map[comment.id] = comment
      comment.replies = []
    end

    comments
      .reject { |comment| comment.parent_id.nil? }
      .each do |comment|
      if (parent_comment = comment_map.fetch(comment.parent_id))
        parent_comment.replies.unshift(comment)
      end
    end

    comments.select { |comment| comment.parent_id.nil? }
  end

  class << self
    def create_proposal(attrs)
      proposal = new(
        id: attrs.fetch(:id, nil),
        user: User.find_by(address: attrs.fetch(:proposer, nil)),
        stage: :idea
      )

      return [:invalid_data, proposal.errors] unless proposal.valid?
      return [:database_error, proposal.errors] unless proposal.save

      [:ok, proposal]
    end

    def comment(proposal, user, parent_comment, attrs)
      if parent_comment &&
         parent_comment.depth >= (COMMENT_MAX_DEPTH - 1)
        return [:maximum_comment_depth, nil]
      end

      comment = Comment.new(
        body: attrs.fetch(:body, nil),
        stage: proposal.stage,
        proposal: proposal,
        user: user
      )

      return [:invalid_data, comment.errors] unless comment.valid?
      return [:database_error, comment.errors] unless comment.save

      parent_comment&.add_child(comment)

      [:ok, comment]
    end

    def delete_comment(user, comment)
      unless Ability.new(user).can?(:delete, comment)
        return [:unauthorized_action, nil]
      end

      comment.discard

      [:ok, comment]
    end

    def like(user, proposal)
      attrs = { user_id: user.id, proposal_id: proposal.id }

      return [:already_liked, nil] if ProposalLike.find_by(attrs)

      result = nil

      ActiveRecord::Base.transaction do
        ProposalLike.new(attrs).save!
        proposal.update!(likes: proposal.proposal_likes.count)

        result = [:ok, proposal]
      end

      result
    end

    def unlike(user, proposal)
      attrs = { user_id: user.id, proposal_id: proposal.id }

      return [:not_liked, nil] unless (like = ProposalLike.find_by(attrs))

      result = nil

      ActiveRecord::Base.transaction do
        like.destroy!
        proposal.update!(likes: proposal.proposal_likes.count)

        result = [:ok, proposal]
      end

      result
    end
  end
end
