# frozen_string_literal: true

class EthereumApi
  SERVER_URL = ENV.fetch('INFURA_SERVER_URL') { 'http://localhost:8545/' }

  class << self
    def get_latest_block
      ok, result_or_error = unwrap_result(request_ethereum_server('eth_blockNumber', []))

      return [ok, result_or_error] unless ok == :ok

      get_block_by_block_number(result_or_error)
    end

    def get_block_by_block_number(block_number)
      unwrap_result(request_ethereum_server('eth_getBlockByNumber', [block_number, false]))
    end

    private

    def request_ethereum_server(method_name, method_args)
      uri = URI.parse(SERVER_URL)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = uri.scheme == 'https'

      req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      req.body = {
        jsonrpc: '2.0',
        method: method_name,
        params: method_args,
        id: 1
      }.to_json

      begin
        res = https.request(req)

        result = JSON.parse(res.body).dig('result')

        [:ok, result]
      rescue StandardError
        [:error, nil]
      end
    end

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
