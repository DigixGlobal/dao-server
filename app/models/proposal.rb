# frozen_string_literal: true

class Proposal < ActiveRecord::Base
  include StageField

  belongs_to :user
  has_many :comments, -> { where(parent_id: nil) }

  validates :stage,
            presence: true
  validates :user,
            presence: true,
            uniqueness: true

  def threads
    Comment
      .where(proposal_id: id)
      .order(created_at: :desc)
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
  end
end
