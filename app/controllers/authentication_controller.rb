# frozen_string_literal: true

class AuthenticationController < ApplicationController
  before_action :check_info_server_request, only: %i[cleanup_challenges]

  def_param_group :challenge do
  end

  api :POST, 'authorization',
      <<~EOS
        Get an access token by requesting for a authentication challenge.
      EOS
  see 'authentication#prove'
  param :address, /0x\w+{40}/, desc: "The user's address",
                               required: true
  formats [:json]
  returns desc: 'User challenge' do
    property :id, Integer, desc: 'Challenge id'
    property :challenge, String, desc: 'Challenge string'
    property :created_at, String, desc: 'Creation UTC date time'
    property :updated_at, String, desc: 'Last modified UTC date time'
  end
  error code: :ok,
        meta: { error: :address_not_found }
  example <<~EOS
    {
      "result": {
        "id": 3,
        "challenge": "260",
        "createdAt": "2018-12-17T09:54:17.000+08:00",
        "updatedAt": "2018-12-17T09:54:17.000+08:00"
      }
    }
  EOS
  def challenge
    result, challenge_or_error =
      Challenge.create_new_challenge(challenge_params)

    case result
    when :user_not_found
      render json: error_response(challenge_or_error || result),
             status: :not_found
    else # :ok
      render json: result_response(challenge_or_error)
    end
  end

  api :PUT, 'authorization',
      <<~EOS
        Prove an authentication challenge and receive an access token.

        To use the authentication, you need to put `access-token`, `client` and `uid`
        in the request header. In particular, you should store the `result` in a variable
        and just append this object to the request headers.
      EOS
  param :address, /0x\w+{40}/, desc: "The user's address",
                               required: true
  param :challenge_id, Integer, desc: 'The id of the challenge',
                                required: true
  param :message, String, desc: 'The authentication challenge',
                          required: true
  param :signature, String,
        required: true,
        desc: <<~EOS
          The challenge signed with the user's wallet.

          For MyEtherWallet, it is https://www.myetherwallet.com/signmsg.html
        EOS
  formats [:json]
  returns desc: 'Access token' do
    property :access_token, String, desc: 'Access token for the user'
    property :token_type, String, desc: 'Token type'
    property :client, String, desc: 'Device code of the user'
    property :expiry, String, desc: 'Expiry epoch date in seconds'
    property :uid, String, desc: 'Token id of the user'
  end
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        meta: { error: :challenge_not_found },
        desc: 'Challenge with the given `challenge_id` could not be found'
  error code: :ok,
        meta: { error: :challenge_already_proven },
        desc: 'Proven challenge cannot be proven again'
  error code: :ok,
        meta: { error: :address_not_equal },
        desc: 'Cannot prove a challenge of another user'
  error code: :ok,
        meta: { error: :challenge_failed },
        desc: 'Challenge or message is incorrect'
  example <<~EOS
    {
      "result": {
        "access-token": "VFM5mqyUaCeFjOV34xCrYg",
        "token-type": "Bearer",
        "client": "RBLfkPmsuzeimlQ-VEhh5g",
        "expiry": "1546223451",
        "uid": "387221"
      }
    }
  EOS
  def prove
    challenge_id = prove_params.fetch(:challenge_id, '')
    unless (challenge = Challenge.find_by(id: challenge_id))
      return render json: error_response(:challenge_not_found)
    end

    result, challenge_or_error = Challenge.prove_challenge(
      challenge,
      prove_params
    )

    case result
    when :challenge_already_proven, :challenge_failed, :address_not_equal
      render json: error_response(challenge_or_error || result)
    else
      sign_in(:user, challenge.user)
      auth_token = challenge.user.create_new_auth_token
      render json: result_response(auth_token)
    end
  end

  api :DELETE, 'authorizations/old',
      <<~EOS
        Delete old #{Challenge::CHALLENGE_AGE} day(s) proven challenges.

        Triggered by a scheduler internally. Not to be used directly.
      EOS
  formats [:json]
  returns desc: 'Number of old challenges deleted' do
    property :result, Integer, desc: 'Result data'
  end
  meta authorization: :nonce
  example <<~EOS
    {
      "result": 1
    }
  EOS
  def cleanup_challenges
    result, count = Challenge.cleanup_challenges

    case result
    when :ok
      render json: result_response(count)
    else # Should not happen
      render json: error_response,
             status: :server_error
    end
  end

  private

  def challenge_params
    params.permit(:address)
  end

  def prove_params
    params.permit(:address, :challenge_id, :message, :signature)
  end
end
