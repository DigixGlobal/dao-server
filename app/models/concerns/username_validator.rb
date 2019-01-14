# frozen_string_literal: true

class UsernameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value&.start_with?('user') &&
       record.errors.add(attribute, 'must not start with `user`')
    end
  end
end
