# frozen_string_literal: true

require 'info_server'

class InfoApi
  SERVER_URL = InfoServer::SERVER_URL

  class << self
    def list_proposals
      ok, records_or_error = unwrap_result(InfoServer.request_info_server('GET', '/proposals/all', {}))

      return [ok, records_or_error] unless ok == :ok

      new_records = records_or_error.map do |record|
        if (versions = record.fetch('proposal_versions', nil))
          latest_version = versions.last
          proposal = latest_version.fetch('dijix_object')

          record.merge(proposal.slice('title', 'description', 'details', 'milestones'))
        else
          record
        end
      end

      [ok, new_records]
    end

    def fetch_points(addresses)
      query = addresses
              .map { |address| "address=#{address}" }
              .join('&')
      unwrap_result(InfoServer.request_info_server('GET', "/points?#{query}", address: addresses))
    end

    def approve_kyc(kyc)
      return [:kyc_not_approved, nil] unless kyc.status.to_sym == :approving

      payload = {
        address: kyc.user.address,
        id_expiration: kyc.expiration_date.to_time.to_i
      }

      unwrap_result(InfoServer.request_info_server('POST', '/kyc/approve', payload))
    end

    private

    def unwrap_result(result)
      success = result[0]

      if success == :ok
        data = result[1]

        [:ok, convert_hash_keys(data)]
      else
        result
      end
    end

    def convert_hash_keys(value)
      case value
      when Array
        value.map { |v| convert_hash_keys(v) }
      when Hash
        value.deep_transform_keys!(&:underscore)
      else
        value
      end
    end
  end
end
