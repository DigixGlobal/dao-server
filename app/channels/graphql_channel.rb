# frozen_string_literal: true

class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user

    @subscription_ids = []
  end

  def execute(data)
    query = data['query']
    variables = ensure_hash(data['variables'])
    operation_name = data['operationName']
    context = {
      current_user: current_user,
      current_user_id: current_user.id,
      channel: self
    }

    result = DaoServerSchema.execute(
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = {
      result: result.subscription? ? { data: nil } : result.to_h,
      more: result.subscription?
    }

    if result.context[:subscription_id]
      @subscription_ids << context[:subscription_id]
    end

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      DaoServerSchema.subscriptions.delete_subscription(sid)
    end
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
end
