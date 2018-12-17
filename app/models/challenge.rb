# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :user

  validates :challenge,
            presence: true

  def as_json(options = {})
    serializable_hash(options.merge(except: %i[proven user_id]))
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end
end
