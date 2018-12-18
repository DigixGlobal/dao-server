# frozen_string_literal: true

class UserController < ApplicationController
  before_action :check_info_server_request, only: [:new_user]
  before_action :authenticate_user!, only: [:details]

  def_param_group :user do
    property :id, Integer, desc: "The user's id"
    property :address, /0x\w+{40}/, desc: "The user's address"
    property :created_at, String, desc: 'Creation UTC date time'
    property :updated_at, String, desc: 'Last modified UTC date time'
  end

  api :POST, 'user',
      <<~EOS
        Create a new user.

        Used by info-server.
      EOS
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :address, /0x\w+{40}/, desc: "The user's address",
                                 required: true
  end
  tags [:info_server]
  formats [:json]
  returns :user, desc: 'Created user'
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        meta: { error: :database_error },
        desc: "Database error. Only if the user's id already exists."
  meta authorization: :nonce
  example <<~EOS
    {
      "result": {
        "id": 83,
        "address": "0x32e8422744054e07f15a4d634747e5bed53b043d",
        "createdAt": "2018-12-17T09:20:19.000+08:00",
        "updatedAt": "2018-12-17T09:20:19.000+08:00"
      }
    }
  EOS
  def new_user
    result, user_or_error = add_new_user(user_params)

    case result
    when :invalid_data, :database_error
      render json: error_response(user_or_error)
    when :ok
      render json: result_response(user_or_error)
    end
  end

  api :GET, 'user/:id',
      "Get a user's details given its id "
  param :id, Integer, desc: 'The id of the user.',
                      required: true
  formats [:json]
  returns :user, desc: 'User with the given id'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "id": 82,
        "address": "0x22e8422744054e07f15a4d634747e5bed53b043d",
        "createdAt": "2018-12-14T11:04:51.000+08:00",
        "updatedAt": "2018-12-14T11:05:55.000+08:00"
      }
    }
  EOS
  def details
    render json: result_response(current_user)
  end

  private

  def is_unique_uid(uid)
    if User.find_by(uid: uid)
      false
    else
      true
    end
  end

  def get_new_uid
    uid = Random.rand(1_000_000)
    uid = Random.rand(1_000_000) until is_unique_uid(uid)
    uid
  end

  def add_new_user(attrs)
    user = User.new(attrs)
    user.uid = get_new_uid

    return [:invalid_data, user.errors] unless user.valid?
    return [:database_error, user.errors] unless user.save

    [:ok, user]
  end

  def user_params
    params
      .permit(payload: [:address])
      .to_hash
      .fetch('payload', {})
      .slice('address')
  end
end
