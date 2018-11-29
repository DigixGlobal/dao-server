# frozen_string_literal: true

class Proposal < ActiveRecord::Base
  belongs_to :user
  has_many :comments, -> { where(parent_id: nil) }
  enum stage: { idea: 1, draft: 2 }

  validates :id,
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
  end
end
