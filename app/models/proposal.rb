# frozen_string_literal: true

class Proposal < ApplicationRecord
  include StageField
  attribute :proposal_like_id
  attribute :liked

  belongs_to :user
  belongs_to :comment
  has_many :proposal_likes

  validates :proposal_id,
            presence: true,
            uniqueness: true
  validates :stage,
            presence: true
  validates :user,
            presence: true

  def as_json(options = {})
    serializable_hash(
      except: %i[id],
      include: { user: { only: :address } }
    )
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end

  def user_like(user)
    ProposalLike.find_by(proposal_id: id, user_id: user.id)
  end

  def user_liked?(user)
    !ProposalLike.find_by(user_id: user.id, proposal_id: id).nil?
  end

  class << self
    def select_user_proposals(user, attrs)
      query = Proposal
              .preload(:user)
              .joins("LEFT OUTER JOIN proposal_likes ON proposal_likes.proposal_id = proposals.id AND proposal_likes.user_id = #{user.id}")
              .select('proposal_likes.id AS liked', :proposal_id, :user_id, :comment_id, :stage, :likes, :created_at, :updated_at)

      if (ids = attrs.fetch(:proposal_ids, nil))
        query = query.where(proposal_id: ids)
      end

      if (stage = attrs.fetch(:stage, nil))
        query = query.where(stage: stage)
      end

      if (liked = attrs.fetch(:liked, nil))
        query = case liked
                when 'not'
                  query.where('proposal_likes.user_id IS NULL')
                else
                  query.where('proposal_likes.user_id IS NOT NULL')
                end
      end

      case attrs.fetch(:sort_by, nil)
      when :asc, 'asc'
        query = query.order('created_at ASC')
      when :desc, 'desc'
        query = query.order('created_at DESC')
      else
        query = query.order('created_at ASC')
      end

      query
        .all
        .map do |proposal|
          proposal.liked = !proposal.liked.nil?
          proposal
        end
    end

    def create_proposal(attrs)
      proposal = new(
        proposal_id: attrs.fetch(:proposal_id, nil),
        user: User.find_by(address: attrs.fetch(:proposer, nil)),
        stage: :idea
      )

      proposal.comment = Comment.new(
        body: 'ROOT',
        stage: proposal.stage,
        user: proposal.user
      )

      return [:invalid_data, proposal.errors] unless proposal.valid?
      return [:database_error, proposal.errors] unless proposal.save

      [:ok, proposal]
    end

    def like(user, proposal)
      unless Ability.new(user).can?(:like, proposal)
        return [:already_liked, nil]
      end

      ActiveRecord::Base.transaction do
        ProposalLike.new(user_id: user.id, proposal_id: proposal.id).save!
        proposal.update!(likes: proposal.proposal_likes.count)
      end

      [:ok, proposal]
    end

    def unlike(user, proposal)
      return [:not_liked, nil] unless Ability.new(user).can?(:unlike, proposal)

      ActiveRecord::Base.transaction do
        ProposalLike.find_by(user_id: user.id, proposal_id: proposal.id).destroy!
        proposal.update!(likes: proposal.proposal_likes.count)
      end

      [:ok, proposal]
    end
  end
end
