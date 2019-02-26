# frozen_string_literal: true

class Subscriptions::BaseSubscription < GraphQL::Schema::Subscription
  object_class Types::Base::BaseObject
  field_class Types::Base::BaseField
end
