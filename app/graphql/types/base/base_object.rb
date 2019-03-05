# frozen_string_literal: true

module Types
  module Base
    class BaseField < GraphQL::Schema::Field
      def initialize(*args, scope: false, **kwargs, &block)
        super
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField

      def self.visible?(context)
        authorized?(nil, context)
      end

      def self.accessible?(context)
        authorized?(nil, context)
      end

      def self.authorized?(_object, _context)
        true
      end
    end
  end
end
