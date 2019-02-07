# frozen_string_literal: true

module Resolvers
  class Base < GraphQL::Schema::Resolver
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
