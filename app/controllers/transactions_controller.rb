require 'json'

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

    # TODO: check for nonce also
    if computedSig === request.headers["ACCESS-SIGN"] && retrievedNonce > currentNonce.nonce
      puts "hello correct signature"
      # TODO: save the latest retrieved nonce
      # TODO: use `body` and do the required changes to the pending transactions
      render json: { status: 200, msg: "correct" }
    else
      puts "bye wrong signature"
      render json: { status: 403, msg: "wrong" }
    end
  end

  def new
    authenticate_user!
    params[:txhash] or return error_response
    params[:title] or return error_response
    txhash = params[:txhash].downcase

    return error_response('duplicateTxhash') if Transaction.find_by(txhash: txhash)
    new_tx = Transaction.new(txhash: txhash, title: params[:title], user: current_user)
    puts "new_tx = #{new_tx}"
    new_tx.save
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
end
