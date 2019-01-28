# frozen_string_literal: true

class User < ApplicationRecord
  devise :rememberable, :trackable
  include DeviseTokenAuth::Concerns::User

  has_many :challenges
  has_many :transactions
  has_one :kyc, -> { kept }

  has_and_belongs_to_many :groups

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
                      message: 'only allows letters, numbers and underscore' },
            username: true
  validates :email,
            allow_nil: true,
            uniqueness: true,
            format: { with: /\A(\S+)@(.+)\.(\S+)\z/,
                      message: 'should be valid' }

  def display_name
    username.nil? ? "user#{uid}" : username
  end

  def as_json(options = {})
    serializable_hash(options.merge(except: %i[provider uid], methods: [:display_name]))
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end

  def self.seed
    officer_address = ENV.fetch('KYC_OFFICER_ADDRESS') { '0x97be8ff9065ce5f3d562cb6b458cde88c8307edf' }

    add_officer(officer_address)
  end

  def self.add_officer(address)
    unless (user = User.find_by(address: address))
      user = User.new(
        uid: Random.rand(1_000_000..1_999_999),
        address: address
      )

      user.save
    end

    begin
      user.groups << Group.find_by(name: Group.groups[:kyc_officer])
    rescue ActiveRecord::RecordNotUnique
      # Already added
    end
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

      return [:invalid_data, audit.errors] unless audit.save

      [:ok, updated_user]
    end
  end
end
