# frozen_string_literal: true

class TransactionsController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[update_hashes ping]
  before_action :authenticate_user!,
                only: %i[new list]

  def_param_group :transaction do
    property :id, Integer, desc: 'Transaction id'
    property :user_id, Integer, desc: 'Creator user id of the transaction'
    property :title, String, desc: 'Transaction title'
    property :txhash, String, desc: 'Transaction hash'
    property :status, Transaction::STATUSES, desc: 'Transaction status'
    property :block_number, String, desc: 'Transaction block number'
    property :created_at, String, desc: 'Creation UTC date time'
    property :updated_at, String, desc: 'Last modified UTC date time'
  end

  api :PUT, 'transactions/seen',
      <<~EOS
        Update transactions to be seen.

        Used by info-server.
      EOS
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :transactions, Array, desc: 'Transactions to be marked as seen',
                                required: true do
      param :txhash, String, desc: 'Transaction hash'
    end
    param :block_number, String, desc: 'Transaction block number',
                                 required: true
  end
  meta authorization: :nonce
  tags [:info_server]
  formats [:json]
  returns desc: 'Seen response' do
    property :result, String, 'Seen constant'
  end
  example <<~EOS
    {
            "result": "seen"
    }
  EOS

  api :PUT, 'transactions/confirmed',
      <<~EOS
        Update transactions to be confirmed or failed.

        Used by info-server.
      EOS
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :success, Array, desc: 'Transactions to be marked as confirmed',
                           required: true do
      param :txhash, String, desc: 'Transaction hash'
    end
    param :failed, Array, desc: 'Transactions to be marked as failed',
                          required: true do
      param :txhash, String, desc: 'Transaction hash'
    end
  end
  meta authorization: :nonce
  tags [:info_server]
  formats [:json]
  returns desc: 'Confirmed response' do
    property :result, String, 'Confirmed constant'
  end
  example <<~EOS
    {
            "result": "confirmed"
    }
  EOS

  def update_hashes
    case params.fetch(:type, nil)
    when 'seen'
      payload = seen_transactions_params
      transactions = payload.fetch(:transactions, [])
      block_number = payload.fetch(:block_number, '')

      unless transactions.empty?
        result, transactions_or_errors = seen_transactions(
          transactions.map { |e| e.fetch(:txhash, '') },
          block_number
        )

        broadcast_transactions(transactions_or_errors) if result == :ok
      end

      render json: result_response(:seen)
    when 'confirmed'
      payload = confirmed_transactions_params
      success_txn_hashes = payload
                           .fetch(:success, [])
                           .map { |e| e.fetch(:txhash, '') }
      failed_txn_hashes = payload
                          .fetch(:failed, [])
                          .map { |e| e.fetch(:txhash, '') }

      unless success_txn_hashes.empty?
        result, transactions_or_errors = confirm_transactions(success_txn_hashes)

        broadcast_transactions(transactions_or_errors) if result == :ok
      end

      unless failed_txn_hashes.empty?
        result, transactions_or_errors = fail_transactions(failed_txn_hashes)

        broadcast_transactions(transactions_or_errors) if result == :ok
      end

      render json: result_response(:confirmed)
    else
      render json: error_response(:invalid_action),
             status: :unprocessable_entity
    end
  end

  api :POST, 'transactions',
      <<~EOS
        Create a new transaction
      EOS
  param :title, String, desc: "The transaction's address",
                        required: true
  param :txhash, String, desc: "The transaction's hash",
                         required: true
  param :type, [1],
        required: false,
        desc: <<~EOS
          The transaction type.

          - 1 :: CLAIM_RESULT
        EOS
  param :project, String,
        required: false,
        desc: <<~EOS
          If the transaction is about a proposal,
           this is the proposal Eth address ID.
        EOS
  formats [:json]
  returns :transaction, desc: 'Created transaction'
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        meta: { error: :database_error },
        desc: 'Database error. Only if the transaction hash already exists.'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "id": 1,
        "title": "Random Hash 0x0000000000000000000001257255554755254994",
        "txhash": "0x0000000000000000000001257255554755254994",
        "status": "pending",
        "blockNumber": null,
        "userId": 82,
        "createdAt": "2018-12-17T10:43:18.000+08:00",
        "updatedAt": "2018-12-17T10:43:18.000+08:00"
      }
    }
  EOS
  def new
    result, transaction_or_error = add_new_transaction(
      current_user,
      add_transactions_params
    )

    case result
    when :invalid_data, :database_error
      render json: error_response(transaction_or_error)
    when :ok
      InfoServer.update_hashes([transaction_or_error.txhash.downcase])

      render json: result_response(transaction_or_error)
    end
  end

  api :GET, 'transactions?page=:page&per_page=:per_page',
      <<~EOS
        Fetch a batch of transactions via standard table pagination.
      EOS
  param :all, String, desc: 'A flag to disable pagination and return all transactions if present'
  param :status, %i[pending],
        desc: <<~EOS
          Filter transactions by their status.

          - pending ::
            Filter claim type transactions
        EOS
  param :page, Integer, desc: 'Batch page'
  param :per_page, Integer, desc: 'Batch page size'
  formats [:json]
  returns array_of: :transaction, desc: 'List of paginated transaction sorted by latest transaction'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": [
        {
          "id": 1,
          "title": "Random Hash 0x0000000000000000000001257255554755254994",
          "txhash": "0x0000000000000000000001257255554755254994",
          "status": null,
          "blockNumber": null,
          "userId": 82,
          "createdAt": "2018-12-17T10:43:18.000+08:00",
          "updatedAt": "2018-12-17T10:43:18.000+08:00"
        }
      ]
    }
  EOS
  def list
    query = current_user.transactions.order('created_at DESC')

    if params.fetch(:status, nil) == 'pending'
      query = query.where(transaction_type: 1)
    end

    paginated_transactions = if params.fetch(:all, nil)
                               query
                             else
                               paginate(
                                 query,
                                 per_page: params.fetch(:per_page, 10),
                                 page: params.fetch(:page, 1)
                               )
                             end

    render json: result_response(paginated_transactions)
  end

  api :GET, 'transaction',
      <<~EOS
        Get a transaction's detail by its transaction hash
      EOS
  param :txhash, String, desc: 'Transaction hash'
  formats [:json]
  returns :transaction, desc: 'Transaction with the given hash'
  error code: :ok,
        meta: { error: :transaction_not_found },
        desc: 'Transaction with the given hash not found'
  example <<~EOS
    {
      "result": {
        "id": 1,
        "title": "Random Hash 0x0000000000000000000001257255554755254994",
        "txhash": "0x0000000000000000000001257255554755254994",
        "status": "pending",
        "blockNumber": null,
        "userId": 82,
        "createdAt": "2018-12-17T10:43:18.000+08:00",
        "updatedAt": "2018-12-17T10:43:18.000+08:00"
      }
    }
  EOS
  def find
    case (transaction = Transaction.find_by(txhash: params.fetch(:txhash, '')))
    when nil
      render json: error_response(:transaction_not_found)
    else
      render json: result_response(transaction)
    end
  end

  api :POST, 'transactions/ping', <<~EOS
    An extra endpoint for testing the nonce validation.
  EOS
  meta authorization: :nonce
  formats [:json]
  returns desc: 'A blank response' do
    property :result, String, desc: 'Blank response'
  end
  def ping
    Rails.logger.info("body from test_server: #{request.body.inspect}")

    render json: result_response
  end

  private

  def add_new_transaction(user, attrs)
    attrs[:transaction_type] = attrs.delete(:type)

    transaction = Transaction.new(attrs)
    transaction.user = user

    return [:invalid_data, transaction.errors] unless transaction.valid?
    return [:database_error, transaction.errors] unless transaction.save

    [:ok, transaction]
  end

  def confirm_transactions(txn_hashes)
    source = Transaction.where(txhash: txn_hashes)

    source.update_all(status: 'confirmed')

    [:ok, source.all]
  end

  def fail_transactions(txn_hashes)
    source = Transaction.where(txhash: txn_hashes)

    source.update_all(status: 'failed')

    [:ok, source.all]
  end

  def seen_transactions(txn_hashes, block_number)
    source = Transaction.where(txhash: txn_hashes)

    source.update_all(block_number: block_number, status: 'seen')

    [:ok, source.all]
  end

  def broadcast_transactions(transactions)
    return :ok if transactions.empty?

    transactions.each do |transaction|
      DaoServerSchema.subscriptions.trigger(
        'transactionUpdated',
        { proposal_id: transaction.project },
        { transaction: transaction },
        {}
      )
    end

    :ok
  end

  def add_transactions_params
    params.permit(:title, :txhash, :type, :project)
  end

  def seen_transactions_params
    return {} if params.fetch(:payload, nil).nil?

    params.require(:payload).permit(:block_number, transactions: [:txhash])
  end

  def confirmed_transactions_params
    return {} if params.fetch(:payload, nil).nil?

    params.require(:payload).permit(success: [:txhash], failed: [:txhash])
  end
end
