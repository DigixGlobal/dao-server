# frozen_string_literal: true

class Comment < ActiveRecord::Base
  attribute :replies

  include StageField
  include Discard::Model
  has_closure_tree(order: 'created_at DESC')

  belongs_to :user

  belongs_to :proposal

  validates :body,
            presence: true,
            length: { maximum: 10_000 }
  validates :stage,
            presence: true
  validates :user,
            presence: true
  validates :proposal,
            presence: true

  def as_json(options = {})
    serializable_hash(except: %i[body replies])
      .merge(
        body: discarded? ? nil : body,
        replies: replies&.map { |reply| reply.as_json(options) }
      )
  end

  class << self
    def delete(user, comment)
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
