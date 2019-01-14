# frozen_string_literal: true

class UserAudit < ApplicationRecord
  validates :user_id,
            presence: true
  validates :event,
            presence: true
  validates :field,
            presence: true
  validates :old_value,
            presence: true,
            allow_blank: true
  validates :new_value,
            presence: true,
            allow_blank: true
end
