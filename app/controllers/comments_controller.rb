# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!,
                only: %i[like unlike]

  def like
  end

  def unlike
  end
end
