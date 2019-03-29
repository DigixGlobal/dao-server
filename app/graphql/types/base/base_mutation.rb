# frozen_string_literal: true

module Types
  module Base
    class BaseMutation < GraphQL::Schema::RelayClassicMutation
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

      class UserErrorType < Types::Base::BaseObject
        description 'A user-readable error'

        field :message, String,
              null: false,
              description: 'A description of the error'
        field :field, String,
              null: true,
              description: 'Which input final value this error came from'
      end

      def sanitize_attrs(attrs)
        attrs.transform_values do |value|
          case value
          when String
            Sanitize.fragment(value)
          else
            value
          end
        end
      end

      def model_result(key, model)
        result = {}
        result[key] = model
        result[:errors] = []

        result
      end

      def model_errors(key, model_errors)
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
  end
end
