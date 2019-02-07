# frozen_string_literal: true

class CountryValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    values = Rails.configuration.countries.map { |country| country['value'] }
    unless value && values.member?(value)
      record.errors.add(attribute, 'must be a valid country value')
    end
  end
end
