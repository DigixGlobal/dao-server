# frozen_string_literal: true

class AuthenticationController < ApplicationController
  CHALLENGE_LENGTH = 10

  def challenge
    address = params.fetch(:address, '').downcase

    unless (user = User.find_by(address: address))
      return render json: { error: :address_not_found },
                    status: :not_found
    end

    result, challenge_or_error = create_new_challenge(
      challenge: rand(36 * CHALLENGE_LENGTH).to_s(CHALLENGE_LENGTH),
      user: user
    )

    case result
    when :invalid_data, :database_error
      render json: { errors: challenge_or_error },
             status: :unprocessable_entity
    when :ok
      render json: { result: result,
                     challenge: challenge_or_error },
             status: :ok
    else
      render json: { error: :server_error },
             status: :server_error
    end
  end

  def prove
    unless params.key?(:address) &&
           params.key?(:challenge_id) &&
           params.key?(:signature) &&
           params.key?(:message)
      return render json: { error: :invalid_data,
                            errors: ['wrongParameters'] }
    end

    challenge_id = params.fetch(:challenge_id, '')
    unless (challenge = Challenge.find_by(id: challenge_id))
      return render json: { error: :challenge_not_found,
                            errors: ['challengeNotFound'] }
    end

    if challenge.proven?
      return render json: { error: :challenge_already_proven,
                            errors: ['challengeAlreadyProved'] }
    end

    address = params.fetch(:address, '').downcase
    unless challenge.user.address == address
      return render json: { error: :address_not_equal,
                            errors: ['addressNotMatch'] }
    end

    recovered_address = recover_address(
      params.fetch(:message, ''),
      params.fetch(:signature, '')
    )

    unless recovered_address == address
      return render json: { error: :challenge_failed,
                            errors: ['challengeFailed'] }
    end

    prove_challenge(challenge)

    sign_in(:user, challenge.user)
    auth_token = challenge.user.create_new_auth_token
    render json: auth_token
  end

  private

  def create_new_challenge(attrs)
    challenge = Challenge.new(attrs)

    return [:invalid_data, challenge.errors] unless challenge.valid?
    return [:database_error, challenge.errors] unless challenge.save

    [:ok, challenge]
  end

  def recover_address(message, signature)
    Eth::Utils.public_key_to_address(
      Eth::Key.personal_recover(message, signature)
    ).downcase
  end

  def prove_challenge(challenge)
    challenge.update(proven: true)
  end
end
