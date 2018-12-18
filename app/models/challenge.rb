# frozen_string_literal: true

class Challenge < ApplicationRecord
  CHALLENGE_LENGTH = Rails
                     .configuration
                     .challenges['challenge_length']
                     .to_i

  CHALLENGE_AGE = Rails
                  .configuration
                  .challenges['challenge_age']
                  .to_i

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

    def prove_challenge(challenge, attrs)
      return [:challenge_already_proven, nil] if challenge.proven?

      address = attrs.fetch(:address, '').downcase

      return [:address_not_equal, nil] unless challenge.user.address == address

      recovered_address = recover_address(
        attrs.fetch(:message, ''),
        attrs.fetch(:signature, '')
      )

      return [:challenge_failed, nil] unless recovered_address == address

      challenge.update(proven: true)

      [:ok, challenge]
    end

    def cleanup_challenges
      deleted_records = Challenge
                        .where('created_at < ? AND proven = ?', CHALLENGE_AGE.day.ago, true)
                        .delete_all

      [:ok, deleted_records]
    end

    private

    def recover_address(message, signature)
      Eth::Utils.public_key_to_address(Eth::Key.personal_recover(message, signature)).downcase
    rescue TypeError, NoMethodError
      ''
    end
  end
end
