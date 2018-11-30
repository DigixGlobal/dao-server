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
      return [:already_deleted, nil] if comment.discarded?

      unless Ability.new(user).can?(:delete, comment)
        return [:unauthorized_action, nil]
      end

      comment.discard
      comment.descendants.each(&:discard)

      [:ok, comment]
    end
  end
end
