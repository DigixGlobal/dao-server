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

  def threads
    comments
      .kept
      .order(created_at: :desc)
      .group_by(&:stage)
      .map do |key, stage_comments|
      [
        key,
        stage_comments
          .map(&:hash_tree)
          .flat_map do |comment_map|
          normalize_hash_map(comment_map, :replies)
        end

      ]
    end
      .to_h
  end

  private

  def normalize_hash_map(hash_map, children_key = :children)
    hash_map
      .map do |entity, child_map|
        if entity.discarded?
          nil
        else
          unless child_map.empty?
            entity[children_key] = normalize_hash_map(child_map, children_key)
          end

          entity
        end
      end
      .reject(&:nil?)
  end

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
