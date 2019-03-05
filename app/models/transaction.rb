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
  validates :transaction_type,
            presence: false,
            allow_blank: true,
            numericality: true,
            inclusion: { in: [1] }
  validates :project,
            presence: false

  def txhash=(value)
    super(value&.downcase)
  end

  def type
    transaction_type
  end

  def as_json(options = {})
    serializable_hash(options.merge(except: %i[transaction_type], methods: [:type]))
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end
end
