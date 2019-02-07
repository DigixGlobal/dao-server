# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      can :create, Proposal
      can :read, Proposal
      can :delete, Proposal, user_id: user.id
      can :like, Proposal do |proposal|
        proposal.user_like(user).nil?
      end
      can :unlike, Proposal do |proposal|
        !proposal.user_like(user).nil?
      end

      can :create, Comment
      can :read, Comment
      can :comment, Comment do |comment|
        if (proposal = Proposal.find_by(comment_id: comment.root.id))
          proposal && proposal.stage == comment.stage

          comment.root? || comment.stage == proposal.stage
        else
          false
        end
      end
      can :delete, Comment, user_id: user.id
      can :like, Comment do |comment|
        comment.user_like(user).nil?
      end
      can :unlike, Comment do |comment|
        !comment.user_like(user).nil?
      end

      user.groups.pluck(:name).each do |group_name|
        case Group.groups.invert[group_name]
        when 'kyc_officer'
          can :read, User

          can :read, Kyc
          can :approve, Kyc, status: 'pending'
          can :reject, Kyc, status: 'pending'
        end
      end
    end
  end
end
