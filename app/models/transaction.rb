# frozen_string_literal: true

class Transaction < ApplicationRecord
  STATUSES = %i[pending failed confirmed].freeze

  belongs_to :user

  validates :title,
            presence: true
  validates :txhash,
            presence: true,
            uniqueness: true
  validates :block_number,
            presence: false
end
