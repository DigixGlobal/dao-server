# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :check_info_server_request, only: %i[confirmed latest test_server]
  after_action :update_info_server_nonce, only: %i[confirmed latest test_server]

  def confirmed
    body = JSON.parse(request.raw_post)
    txhashes = body['payload'].map { |e| e['txhash'] }
    Transaction.where(txhash: txhashes).update_all(status: 'confirmed')

    render json: { result: :ok,
                   msg: 'correct' }
  end

  def latest
    body = JSON.parse(request.raw_post)
    blockNumber = body['payload']['blockNumber']
    latestTxns = body['payload']['transactions']

    unless latestTxns.empty?
      Transaction.where(txhash: latestTxns).update_all(blockNumber: blockNumber, status: 'seen')
    end

    render json: { result: :ok,
                   msg: 'correct' }
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
    transaction || (return error_response('notFound'))
    render json: transaction
  end

  def test_server
    body = JSON.parse(request.raw_post)

    puts "body from test_server: #{body}"

    render json: { status: 200, msg: 'correct' }
  end

  private

  def notifyInfoServer(txhashes)
    payload = { txns: txhashes }
    res = request_info_server('/transactions/watch', payload)
    seenTxns = JSON.parse(res.body)['result']['seen']
    confirmedTxns = JSON.parse(res.body)['result']['confirmed']
    unless confirmedTxns.empty?
      confirmedTxns.each do |txn|
        Transaction.where(txhash: txn['txhash']).update(status: 'confirmed', blockNumber: txn['blockNumber'])
      end
    end
    unless seenTxns.empty?
      seenTxns.each do |txn|
        Transaction.where(txhash: txn['txhash']).update(status: 'seen', blockNumber: txn['blockNumber'])
      end
    end
  end

  def check_transactions_params
    params.require(:txhash)
    params.permit(:title)
  end
end
