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

  private

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

    def comment(proposal, user, attrs)
      comment = Comment.new(
        body: attrs.fetch(:body, nil),
        stage: proposal.stage,
        proposal: proposal,
        user: user
      )

      return [:invalid_data, comment.errors] unless comment.valid?
      return [:database_error, comment.errors] unless comment.save

      [:ok, comment]
    end
  end
end
