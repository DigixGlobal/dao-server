class UserController < ApplicationController
  before_action :authenticate_user!

  def details
    authenticate_user!
    puts 'authenticated'
    puts "current user = #{current_user}"
    render json: current_user
  end
end
