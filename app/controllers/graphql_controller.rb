# frozen_string_literal: true

class GraphqlController < ApplicationController
  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operation_name]

    current_user&.groups&.reload

    context = {
      current_user: current_user,
      ip_address: request.remote_ip
    }

    puts ['A', request.remote_ip].inspect

    result = DaoServerSchema.execute(
      query,
      variables: variables,
      context: context,
      operation_name: operation_name
    )

    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development e
  end

  private

  def remote_ip(remote_ips)
    if remote_ips
      remote_ips.split(',').first&.strip
    else
      ''
    end
  end

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(e)
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: {
        message: e.message,
        backtrace: e.backtrace
      },
      data: {}
    },
           status: 500
  end
end
