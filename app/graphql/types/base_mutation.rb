# frozen_string_literal: true

class Types::BaseMutation < GraphQL::Schema::RelayClassicMutation
  def self.visible?(context)
    authorized?(nil, context)
  end

  def self.accessible?(context)
    authorized?(nil, context)
  end

  def self.authorized?(_object, _context)
    true
  end

  protected

  class UserErrorType < Types::BaseObject
    description 'A user-readable error'

    field :message, String,
          null: false,
          description: 'A description of the error'
    field :field, String,
          null: true,
          description: 'Which input final value this error came from'
  end

  def model_result(model, key)
    result = {}
    result[key] = model
    result[:errors] = []

    result
  end

  def model_errors(model_errors, key)
    result = {}
    result[key] = nil
    result[:errors] = model_errors.map do |inner_key, _value|
      {
        field: inner_key.to_s,
        message: model_errors.full_messages_for(inner_key).first
      }
    end

    result
  end

  def form_error(key, field = '_FORM', error_message = 'Form Error')
    result = {}
    result[key] = nil
    result[:errors] = [
      {
        field: field,
        message: error_message
      }
    ]

    result
  end
end
