# frozen_string_literal: true

class TransactionsController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[update_hashes ping]
  before_action :authenticate_user!,
                only: %i[new list]

  def update_hashes
    case params.fetch(:type, nil)
    when 'seen'
      payload = params.fetch('payload', {})
      transactions = payload.fetch('transactions', [])
      block_number = payload.fetch('block_number', '')

      unless transactions.empty?
        seen_transactions(
          transactions.map { |e| e.fetch('txhash', '') },
          block_number
        )
      end

      render json: result_response(:seen)
    when 'confirmed'
      txn_hashes = params.fetch('payload', []).map { |e| e.fetch('txhash', '') }
      confirm_transactions(txn_hashes)

      render json: result_response(:confirmed)
    else
      render json: error_response(:invalid_action),
             status: :unprocessable_entity
    end
  end

  def new
    result, transaction_or_error = add_new_transaction(
      current_user,
      transactions_params
    )

    case result
    when :invalid_data, :database_error
      render json: error_response(transaction_or_error)
    when :ok
      InfoServer.update_hashes([transaction_or_error.txhash.downcase])

      render json: result_response(transaction_or_error)
    end
  end

  def list
    render json: result_response(current_user.transactions)
  end

  def find
    case (transaction = Transaction.find_by(txhash: params.fetch(:txhash, '')))
    when nil
      render json: error_response(:transaction_not_found)
    else
      render json: result_response(transaction)
    end
  end

  def ping
    Rails.logger.info("body from test_server: #{request.body.inspect}")

    render json: result_response
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
      .update_all(block_number: block_number, status: 'seen')
  end

  def transactions_params
    params.permit(:title, :txhash)
  end
end
