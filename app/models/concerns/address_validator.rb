# frozen_string_literal: true

class AddressValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value && Eth::Utils.valid_address?(value)
      record.errors.add(attribute, 'must be a valid checksum address')
    end
  end
end
