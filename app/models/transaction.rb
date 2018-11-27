# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :user

  validates :title,
            presence: true
  validates :txhash,
            presence: true,
            uniqueness: true
  validates :blockNumber,
            presence: false
end
