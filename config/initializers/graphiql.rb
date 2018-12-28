# frozen_string_literal: true

# From https://github.com/rmosolgo/graphiql-rails/issues/36#issuecomment-341765388
module GraphiQLRailsEditorsControllerDecorator
  def self.prepended(base)
    base.prepend_before_action :set_auth_headers, only: :show
  end

  protected

  def set_auth_headers
    if (user_id = params.fetch(:user_id, nil)) &&
       (user = User.find_by(id: user_id))
      Rails.logger.info "Using #{user.id} as `current_user`"
      GraphiQL::Rails.config.headers.merge! user.create_new_auth_token
    end
  end
end

GraphiQL::Rails::EditorsController.send :prepend, GraphiQLRailsEditorsControllerDecorator
