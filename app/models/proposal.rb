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

  def user_liked?(user)
    !ProposalLike.find_by(user_id: user.id, proposal_id: id).nil?
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
