# frozen_string_literal: true

class User < ActiveRecord::Base
  devise :rememberable, :trackable
  include DeviseTokenAuth::Concerns::User

  has_many :challenges
  has_many :transactions

  def remove_tokens_after_password_reset
    # override this function in devise_token_auth
  end

  validates :address,
            presence: true,
            uniqueness: true

  validate :address, :checksum_address?

  private

  def checksum_address?
    unless Eth::Utils.valid_address?(address)
      errors.add(:address, 'must be a valid checksum address')
    end
  end
end
