# frozen_string_literal: true

class AuthenticationController < ApplicationController
  CHALLENGE_LENGTH = 10

  def challenge
    address = params.fetch(:address, '').downcase

    unless (user = User.find_by(address: address))
      return render json: { error: :address_not_found },
                    status: :not_found
    end

    puts "Getting challenge for address #{address}"

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
    message = params[:message]
    challenge_id = params[:challenge_id]
    signature = params[:signature]
    address = params[:address].downcase
    unless message && signature && address && challenge_id
      return render json: { errors: ['wrongParameters'] }
    end

    (challenge = Challenge.find(challenge_id)) || (return render json: { errors: ['challengeNotFound'] })
    (challenge.user.address == address) || (return render json: { errors: ['addressNotMatch'] })
    pub_key = Eth::Key.personal_recover(message, signature)
    # TODO: checksum
    address_from_pub_key = Eth::Utils.public_key_to_address(pub_key).downcase
    puts "address_from_pub_key = #{address_from_pub_key}"
    (address_from_pub_key == address) || (return render json: { errors: ['challengeFailed'] })

    # login successfully
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
end
