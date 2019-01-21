# frozen_string_literal: true

class Kyc < ApplicationRecord
  enum status: { not_verified: 0, pending: 1, rejected: 2, approved: 3, expired: 4 }
  enum employment_status: { employed: 0, self_employed: 1, unemployed: 2 }
  enum identification_proof_type: { employed: 0, self_employed: 1, unemployed: 2 }, _prefix: :identification
  enum residence_proof_type: { utility_bill: 0, bank_statement: 1 }, _prefix: :residence

  belongs_to :user

  has_one_attached :residence_proof_image
  has_one_attached :identification_proof_image
  has_one_attached :identification_pose_image
end
