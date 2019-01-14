# frozen_string_literal: true

class User < ApplicationRecord
  devise :rememberable, :trackable
  include DeviseTokenAuth::Concerns::User

  has_many :challenges
  has_many :transactions

  def username=(value)
    super(value.nil? ? nil : value.downcase)
  end

  def remove_tokens_after_password_reset
    # override this function in devise_token_auth
  end

  validates :address,
            presence: true,
            uniqueness: true,
            address: true
  validates :username,
            allow_nil: true,
            uniqueness: true,
            format: { with: /\A[a-zA-Z0-9_]+\Z/,
                      message: 'only allow letters, numbers and underscore' },
            username: true
  validates :email,
            allow_nil: true,
            uniqueness: true,
            format: { with: /\A(\S+)@(.+)\.(\S+)\z/,
                      message: 'only valid email' }

  def as_json(options = {})
    serializable_hash(options.merge(except: %i[provider uid]))
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end

  class << self
    def change_username(user, username)
      return [:username_already_set, nil] if user.username

      updated_user = User.find(user.id)

      unless updated_user.update_attributes(username: username&.downcase)
        return [:invalid_data, updated_user.errors]
      end

      [:ok, updated_user]
    end

    def change_email(user, email)
      updated_user = User.find(user.id)

      unless updated_user.update_attributes(email: email)
        return [:invalid_data, updated_user.errors]
      end

      audit = UserAudit.new(
        user_id: user.id,
        event: 'EMAIL_CHANGE',
        field: 'email',
        old_value: user.email || '',
        new_value: email
      )

      puts audit.errors.inspect unless audit.save

      [:ok, updated_user]
    end
  end
end
