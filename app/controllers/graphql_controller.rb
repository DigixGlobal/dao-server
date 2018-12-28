# frozen_string_literal: true

class GraphqlController < ApplicationController
  before_action :authenticate_user!,
                only: %i[find show select]

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operation_name]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }

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
