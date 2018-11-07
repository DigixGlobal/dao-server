require 'json'
require 'uri'
require 'net/http'
require 'net/https'

class TransactionsController < ApplicationController
  def confirmed
    message = request.method() + request.original_fullpath + request.raw_post + request.headers["ACCESS-NONCE"]

    digest = OpenSSL::Digest.new('sha256')
    # TODO: take this from environment variables
    serverSecret = 'this-is-a-secret-between-dao-and-info-server'
    computedSig = OpenSSL::HMAC.hexdigest(digest, serverSecret, message)

    currentNonce = Nonce.find_by(server: 'infoServer')
    retrievedNonce = Integer(request.headers["ACCESS-NONCE"])

    body = JSON.parse(request.raw_post)

    if computedSig === request.headers["ACCESS-SIGN"] && retrievedNonce > currentNonce.nonce
      Nonce.update(currentNonce.id, :nonce => retrievedNonce)
      txhashes = body.map { |e| e["txhash"] }
      Transaction.where(txhash: txhashes).update_all(status: 'confirmed')

      render json: { status: 200, msg: "correct" }
    else
      render json: { status: 403, msg: "wrong" }
    end
  end

  def new
    # authenticate_user!
    check_transactions_params
    txhash = params[:txhash].downcase

    return error_response('duplicateTxhash') if Transaction.find_by(txhash: txhash)
    # new_tx = Transaction.new(txhash: txhash, title: params[:title], user: current_user)
    new_tx = Transaction.new(txhash: txhash, title: params[:title], user: User.find(1))
    new_tx.save
    puts "new_tx = #{new_tx}"

    notifyInfoServer([txhash])
    render json: { success: true, tx: new_tx }
  end

  def list
    authenticate_user!
    transactions = current_user.transactions
    render json: { transactions: transactions }
  end

  def status
    # TODO: sanitize
    transaction = Transaction.find_by(txhash: params[:txhash])
    transaction or return error_response('notFound')
    render json: transaction
  end

  private
  def notifyInfoServer(txhashes)
    # TODO: see if there can be more efficient way
    # something like, incrementAndGet

    payload = { txns: txhashes }
    res = request_info_server('/transactions/watch', payload)
    puts "response is #{res}"
  end

  def check_transactions_params
  	params.require(:txhash)
    params.permit(:title)
  end
end
