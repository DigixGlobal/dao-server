# frozen_string_literal: true

class Proposal < ApplicationRecord
  include StageField

  belongs_to :user
  belongs_to :comment
  has_many :proposal_likes

  validates :stage,
            presence: true
  validates :user,
            presence: true,
            uniqueness: true

  def user_like(user)
    ProposalLike.find_by(proposal_id: id, user_id: user.id)
  end

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

  def user_liked?(user)
    !ProposalLike.find_by(user_id: user.id, proposal_id: id).nil?
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

      proposal.comment = Comment.new(
        body: 'ROOT',
        stage: proposal.stage,
        user: proposal.user
      )

      return [:invalid_data, proposal.errors] unless proposal.valid?
      return [:database_error, proposal.errors] unless proposal.save

      [:ok, proposal]
    end

    def like(user, proposal)
      unless Ability.new(user).can?(:like, proposal)
        return [:already_liked, nil]
      end

      ActiveRecord::Base.transaction do
        ProposalLike.new(user_id: user.id, proposal_id: proposal.id).save!
        proposal.update!(likes: proposal.proposal_likes.count)
      end

      [:ok, proposal]
    end

    def unlike(user, proposal)
      return [:not_liked, nil] unless Ability.new(user).can?(:unlike, proposal)

      ActiveRecord::Base.transaction do
        ProposalLike.find_by(user_id: user.id, proposal_id: proposal.id).destroy!
        proposal.update!(likes: proposal.proposal_likes.count)
      end

      [:ok, proposal]
    end
  end
end
