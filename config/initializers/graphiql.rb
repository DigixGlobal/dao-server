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

      user_auth_token = user.create_new_auth_token

      GraphiQL::Rails.config.headers['access-token'] = ->(context) { user_auth_token['access-token'] }
      GraphiQL::Rails.config.headers['token-type'] = ->(context) { user_auth_token['token-type'] }
      GraphiQL::Rails.config.headers['client'] = ->(context) { user_auth_token['client'] }
      GraphiQL::Rails.config.headers['expiry'] = ->(context) { user_auth_token['expiry'] }
      GraphiQL::Rails.config.headers['uid'] = ->(context) { user_auth_token['uid'] }

      GraphiQL::Rails.config.logo = "Current User Address: #{user.address}"
    else
      GraphiQL::Rails.config.title = 'DAO GraphQL unauthorized'
    end
  end
end

GraphiQL::Rails.config.logo = 'No Current User. Add the query param `user_id` and restart if you need it.'
GraphiQL::Rails.config.title = 'DAO API GraphiQL'
GraphiQL::Rails::EditorsController.send :prepend, GraphiQLRailsEditorsControllerDecorator
