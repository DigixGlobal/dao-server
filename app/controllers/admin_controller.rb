# frozen_string_literal: true
require 'ethereum_api'
class AdminController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[update_hashes]


  api :POST, 'admin/kyc_approval_update', <<~EOS
    Update KYC approval transactions for tracking purposes
  EOS
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :approved, Array, desc: 'KYC transactions that were marked approved',
                            required: true do
      param :address, String, desc: 'KYC user address'
      param :txhash, String, desc: 'Transaction hash'
      param :id_expiration, Integer, desc: 'KYC document expiration'
    end
  end
  meta authorization: :nonce
  formats [:json]
  returns desc: 'A blank response' do
    property :result, String, desc: 'Blank response'
  end
  def update_hashes
    payload = update_hashes_params
    hashes = payload.fetch(:approved, [])

    _ok = Kyc.update_kyc_hashes(hashes)

    render json: result_response
  end

  def test
    render json: EthereumApi.get_latest_block
  end

  private

  def update_hashes_params
    return {} if params.fetch(:payload, nil).nil?
    return {} if params.fetch(:payload).fetch(:approved, nil).nil?

    params.require(:payload).permit(approved: %i[txhash address])
  end
end
