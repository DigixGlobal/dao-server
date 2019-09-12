# frozen_string_literal: true

require 'ethereum_api'

class WatchingTransaction < ApplicationRecord
  before_create :set_uuid

  belongs_to :user

  validates :transaction_object,
            presence: true
  validates :signed_transaction,
            presence: true
  validates :txhash,
            presence: true,
            uniqueness: true

  def set_uuid
    self.id ||= SecureRandom.uuid
    self.group_id ||= id
  end

  def transaction_object
    JSON.parse(super)
  end

  def transaction_object=(value)
    super(JSON.generate(value))
  end

  def txhash=(value)
    super(value&.downcase)
  end

  class << self
    def watch(user, attrs)
      tx = WatchingTransaction.new(
        user: user,
        transaction_object: attrs.fetch(:transaction_object, nil),
        signed_transaction: attrs.fetch(:signed_transaction, nil),
        txhash: attrs.fetch(:txhash, nil)
      )

      return [:invalid_data, tx.errors] unless tx.valid?
      return [:database_error, tx.errors] unless tx.save

      [:ok, tx]
    end

    def resend(user, watching_transaction, attrs)
      transaction_object = attrs.fetch(:transaction_object, nil)
      unless user.id == watching_transaction.user.id
        return [:unauthorized_action, nil]
      end
      unless transaction_object.fetch('nonce', nil) == watching_transaction.transaction_object['nonce']
        return [:invalid_nonce, nil]
      end

      tx = WatchingTransaction.new(
        user: user,
        transaction_object: transaction_object,
        signed_transaction: attrs.fetch(:signed_transaction, nil),
        txhash: attrs.fetch(:txhash, nil),
        group_id: watching_transaction.group_id
      )

      return [:invalid_data, tx.errors] unless tx.valid?
      return [:database_error, tx.errors] unless tx.save

      [:ok, tx]
    end

    def resend_transactions
      group_size = WatchingTransaction.group(:group_id).count
      WatchingTransaction.order('created_at ASC').each do |tx|
        ok_tx, data = EthereumApi.get_transaction_by_hash(tx.txhash)
        if ok_tx == :error
          Rails.logger.info 'Failed to get transaction by hash. Killing job..'
          break
        end
        unless data
          if group_size[tx.group_id] == 1
            ok_send, txhash = EthereumApi.send_raw_transaction(tx.signed_transaction)
            if ok_send == :ok
              Rails.logger.info "Resent transaction #{tx.txhash}, new hash is #{txhash}"
              tx.update_attributes(txhash: txhash)
            else
              Rails.logger.info "Failed to resend #{tx.txhash}"
            end
          else
            Rails.logger.info "Destroying dropped transaction #{tx.txhash}"
            tx.destroy
            group_size[tx.group_id] -= 1
          end
          next
        end

        unless data['block_number'].nil?
          Rails.logger.info "Destroying transactions from mined group #{tx.group_id}"
          WatchingTransaction.where(group_id: tx.group_id).destroy_all
        end
      end
    end
  end
end
