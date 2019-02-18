# frozen_string_literal: true

require 'cancancan'

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
      if user.is_banned
        cannot :comment, Comment
      else
        can :comment, Comment do |comment|
          if (proposal = Proposal.find_by(comment_id: comment.root.id))
            proposal && proposal.stage == comment.stage

            comment.root? || comment.stage == proposal.stage
          else
            false
          end
        end
      end

      can :delete, Comment do |comment|
        comment.user_id == user.id && !comment.is_banned
      end
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
        when 'forum_admin'
          can :manage, User

          can :ban, User do |this_user|
            !this_user.is_banned
          end
          can :unban, User, &:is_banned

          can :ban, Comment do |comment|
            !(comment.discarded? || comment.is_banned)
          end
          can :unban, Comment, &:is_banned
        end
      end
    end
  end
end
