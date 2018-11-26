# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :user

  validates :challenge,
            presence: true
end
