class UserController < ApplicationController

  def details
    authenticate_user!
    puts 'authenticated'
    puts "current user = #{current_user}"
    render json: current_user
  end

  def new_user
    message = request.method() + request.original_fullpath + request.raw_post + request.headers["ACCESS-NONCE"]

    digest = OpenSSL::Digest.new('sha256')
    computedSig = OpenSSL::HMAC.hexdigest(digest, SERVER_SECRET, message)

    currentNonce = Nonce.find_by(server: 'infoServer')
    retrievedNonce = Integer(request.headers["ACCESS-NONCE"])

    body = JSON.parse(request.raw_post)

    if computedSig === request.headers["ACCESS-SIGN"] && retrievedNonce > currentNonce.nonce
      Nonce.update(currentNonce.id, :nonce => retrievedNonce)
      userAddress = body["address"]
      uid = get_new_uid
      u = User.new(address: userAddress, uid: uid)
      u.save

      render json: { status: 200, msg: "correct" }
    else
      render json: { status: 403, msg: "wrong" }
    end
  end

  private
  def get_new_uid
    uid = Random.rand(1000000)
    while (!is_unique_uid(uid)) do
      uid = Random.rand(1000000)
    end
    return uid
  end

  def is_unique_uid(uid)
    if User.find_by(uid: uid)
      return false
    else
      return true
    end
  end
end
