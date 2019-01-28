# frozen_string_literal: true

class RejectionReasonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    reason_codes = Rails.configuration.rejection_reasons
                        .map { |rejection_reason| rejection_reason['value'] }

    unless reason_codes.member?(value)
      record.errors.add(attribute, 'must be a valid rejection reason')
    end
  end
end
