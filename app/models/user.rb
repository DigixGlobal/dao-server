# frozen_string_literal: true

class User < ApplicationRecord
  devise :rememberable, :trackable
  include DeviseTokenAuth::Concerns::User

  has_many :challenges
  has_many :transactions

  def remove_tokens_after_password_reset
    # override this function in devise_token_auth
  end

  validates :address,
            presence: true,
            uniqueness: true,
            address: true

  def as_json(options = {})
    serializable_hash(options.merge(except: %i[provider uid]))
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end
end
