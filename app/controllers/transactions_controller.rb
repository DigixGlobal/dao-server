# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :check_info_server_request, only: %i[confirmed latest test_server]
  after_action :update_info_server_nonce, only: %i[confirmed latest test_server]
  before_action :authenticate_user!, only: %i[new list]

  def confirmed
    txn_hashes = params.fetch('payload', []).map { |e| e.fetch('txhash', '') }
    confirm_transactions(txn_hashes)

    render json: { result: :ok,
                   msg: 'correct' }
  end

  def latest
    payload = params.fetch('payload', {})
    transactions = payload.fetch('transactions', [])
    block_number = payload.fetch('blockNumber', '')

    unless transactions.empty?
      seen_transactions(
        transactions.map { |e| e.fetch('txhash', '') },
        block_number
      )
    end

    render json: { result: :ok,
                   msg: 'correct' }
  end

  def new
    result, transaction_or_error = add_new_transaction(current_user, transactions_params)

    case result
    when :invalid_data, :database_error
      render json: { errors: transaction_or_error }
    when :ok
      InfoServer.update_hashes([transaction_or_error.txhash.downcase])

      render json: { result: result,
                     tx: transaction_or_error }
    else
      render json: { error: :server_error }
    end
  end

  def list
    render json: { transactions: current_user.transactions }
  end

  def status
    case (transaction = Transaction.find_by(txhash: params.fetch(:txhash, '')))
    when nil
      render json: { error: :transaction_not_found }
    else
      render json: transaction
    end
  end

  def test_server
    puts "body from test_server: #{request.body}"

    render json: {  result: :ok,
                    msg: 'correct' }
  end

  private

  def add_new_transaction(user, attrs)
    transaction = Transaction.new(attrs)
    transaction.user = user

    return [:invalid_data, transaction.errors] unless transaction.valid?

    transaction.txhash = transaction.txhash.downcase

    return [:database_error, transaction.errors] unless transaction.save

    [:ok, transaction]
  end

  def confirm_transactions(txn_hashes)
    Transaction
      .where(txhash: txn_hashes)
      .update_all(status: 'confirmed')
  end

  def seen_transactions(txn_hashes, block_number)
    Transaction
      .where(txhash: txn_hashes)
      .update_all(blockNumber: block_number, status: 'seen')
  end

  def transactions_params
    params.permit(:title, :txhash)
  end
end
