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
      can :delete, Comment, user_id: user.id
      can :like, Comment do |comment|
        comment.user_like(user).nil?
      end
      can :unlike, Comment do |comment|
        !comment.user_like(user).nil?
      end
    end
  end
end
