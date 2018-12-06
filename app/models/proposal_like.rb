# frozen_string_literal: true

class ProposalLike < ApplicationRecord
  belongs_to :user
  belongs_to :proposal

  validates :user,
            presence: true
  validates :proposal,
            presence: true
  validates_uniqueness_of :user_id,
                          scope: :proposal_id
end
