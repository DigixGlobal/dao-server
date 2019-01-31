# frozen_string_literal: true

require 'info_server'

class InfoApi
  class << self
    def list_proposals
      ok, records_or_error = unwrap_result(InfoServer.request_info_server('GET', '/proposals/all', {}))

      return [ok, records_or_error] unless ok == :ok

      new_records = records_or_error.map do |record|
        latest_version = record.fetch('proposal_versions').last
        proposal = latest_version.fetch('dijix_object')

        record.merge(proposal.slice('title', 'description', 'details', 'milestones'))
      end

      [ok, new_records]
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
