class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  def error_response(error='Error')
    render json: { error: error }
  end
end
