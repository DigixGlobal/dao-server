class TransactionsController < ApplicationController
  def confirmed
    if verify_info_server_request(request)
      currentNonce = Nonce.find_by(server: 'infoServer')
      retrievedNonce = Integer(request.headers["ACCESS-NONCE"])
      Nonce.update(currentNonce.id, :nonce => retrievedNonce)
      body = JSON.parse(request.raw_post)
      txhashes = body["payload"].map { |e| e["txhash"] }
      Transaction.where(txhash: txhashes).update_all(status: 'confirmed')

      render json: { status: 200, msg: "correct" }
    else
      render json: { status: 403, msg: "wrong" }
    end
  end

  def latest
    if verify_info_server_request(request)
      currentNonce = Nonce.find_by(server: 'infoServer')
      retrievedNonce = Integer(request.headers["ACCESS-NONCE"])
      Nonce.update(currentNonce.id, :nonce => retrievedNonce)

      body = JSON.parse(request.raw_post)
      blockNumber = body["payload"]["blockNumber"]
      latestTxns = body["payload"]["transactions"]
      # update transactions (pending --> seen) (blockNumber)
      Transaction.where(txhash: latestTxns).update_all(blockNumber: blockNumber, status: 'seen')

      render json: { status: 200, msg: "correct" }
    else
      render json: { status: 403, msg: "wrong" }
    end
  end

  def new
    authenticate_user!
    check_transactions_params
    txhash = params[:txhash].downcase

    return error_response('duplicateTxhash') if Transaction.find_by(txhash: txhash)
    new_tx = Transaction.new(txhash: txhash, title: params[:title], user: current_user)
    new_tx.save

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
    payload = { txns: txhashes }
    res = request_info_server('/transactions/watch', payload)
    completedTxns = JSON.parse(res.body)["result"]
    if (completedTxns.length > 0)
      txhashes = completedTxns.map { |e| e["txhash"] }
      Transaction.where(txhash: txhashes).update_all(status: 'confirmed')
    end
  end

  def check_transactions_params
  	params.require(:txhash)
    params.permit(:title)
  end
end
