# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    def initialize(*args, scope: false, **kwargs, &block)
      super
    end
  end

  class BaseObject < GraphQL::Schema::Object
    field_class BaseField
   end
end
