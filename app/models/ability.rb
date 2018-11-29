# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      can :create, Proposal
      can :read, Proposal
      can :destroy, Proposal, user_id: user.id

      can :create, Comment
      can :read, Comment
      can :destroy, Comment, user_id: user.id
    end
  end
end
