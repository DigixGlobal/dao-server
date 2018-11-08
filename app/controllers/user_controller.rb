class UserController < ApplicationController

  def details
    authenticate_user!
    render json: current_user
  end

  def new_user
    if verify_info_server_request(request)
      currentNonce = Nonce.find_by(server: 'infoServer')
      retrievedNonce = Integer(request.headers["ACCESS-NONCE"])
      Nonce.update(currentNonce.id, :nonce => retrievedNonce)
      body = JSON.parse(request.raw_post)
      add_new_user(body["payload"]["address"])

      render json: { status: 200, msg: "correct" }
    else
      render json: { status: 403, msg: "wrong" }
    end
  end

  private
  def is_unique_uid(uid)
    if User.find_by(uid: uid)
      return false
    else
      return true
    end
  end

  def get_new_uid
    uid = Random.rand(1000000)
    while (!is_unique_uid(uid)) do
      uid = Random.rand(1000000)
    end
    return uid
  end

  def add_new_user(userAddress)
    uid = get_new_uid
    u = User.new(address: userAddress, uid: uid)
    u.save
  end
end
