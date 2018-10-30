class AuthenticationController < ApplicationController
  CHALLENGE_LENGTH = 10
  def challenge
    # TODO: sanitize
    address = params[:address].downcase
    user = User.find_by(address: address)

    # TODO: better error handling
    unless user
      return render json: { errors: ["addressNotFound"] }
    end

    puts "Getting challenge for address #{address}"
    new_challenge = Challenge.new(
      challenge: rand(36 * CHALLENGE_LENGTH).to_s(CHALLENGE_LENGTH),
      user: user
    )
    if new_challenge.save
      render json: { challenge: new_challenge }
    else
      render json: { errors: ['Error'] }
    end
  end

  def prove
    message = params[:message]
    challenge_id = params[:challenge_id].to_i
    signature = params[:signature]
    address = params[:address].downcase
    unless message and signature and address and challenge_id
      return render json: { errors: ["wrongParameters"] }
    end

    challenge = Challenge.find(challenge_id) or return render json: { errors: ['challengeNotFound'] }
    # challenge.user.address == address or return render json: { errors: ['addressNotMatch'] }
    # pub_key = Eth::Key.personal_recover(message, signature)
    # # TODO: checksum
    # address_from_pub_key = Eth::Utils.public_key_to_address(pub_key).downcase
    # puts "address_from_pub_key = #{address_from_pub_key}"
    # address_from_pub_key == address or return render json: { errors: ['challengeFailed'] }

    # login successfully
    sign_in(:user, challenge.user)
    auth_token = challenge.user.create_new_auth_token
    render json: auth_token
  end

end
