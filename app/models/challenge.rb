# frozen_string_literal: true

class Challenge < ApplicationRecord
  CHALLENGE_LENGTH = 10

  belongs_to :user

  validates :challenge,
            presence: true

  def as_json(options = {})
    serializable_hash(options.merge(except: %i[proven user_id]))
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end

  class << self
    def create_new_challenge(attrs)
      address = attrs.fetch(:address, '').downcase

      unless (user = User.find_by(address: address))
        return [:user_not_found, nil]
      end

      challenge = Challenge.new(
        challenge: rand(36 * CHALLENGE_LENGTH).to_s(CHALLENGE_LENGTH),
        user: user
      )

      Challenge.where(user_id: user.id, proven: false).delete_all

      return [:database_error, challenge.errors] unless challenge.save

      [:ok, challenge]
    end
  end
end
