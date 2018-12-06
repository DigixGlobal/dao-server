# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      can :create, Proposal
      can :read, Proposal
      can :delete, Proposal, user_id: user.id

      can :create, Comment
      can :read, Comment
      can :delete, Comment, user_id: user.id

      can :like, CommentLike
      can :unlike, CommentLike, user_id: user.id
    end
  end
end
