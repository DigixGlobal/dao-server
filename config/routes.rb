# frozen_string_literal: true

Rails.application.routes.draw do
  post '/api', to: 'graphql#execute'
  apipie

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api'
  end

  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    # confirmations:      'devise_token_auth/confirmations',
    # passwords:          'devise_token_auth/passwords',
    # omniauth_callbacks: 'devise_token_auth/omniauth_callbacks',
    # registrations:      'overrides/registrations',
    # sessions:           'devise_token_auth/sessions',
    # token_validations:  'overrides/token_validations',
  }

  get '/user',
      to: 'user#details'
  post '/user',
       to: 'user#new_user'
  post '/authorization',
       to: 'authentication#challenge'
  put '/authorization',
      to: 'authentication#prove'
  delete '/authorizations/old',
         to: 'authentication#cleanup_challenges'

  get '/transactions/ping',
      to: 'transactions#ping'
  get '/transactions',
      to: 'transactions#list'
  put '/transactions(/:type)',
      to: 'transactions#update_hashes',
      as: 'transactions_update'
  post '/transactions',
       to: 'transactions#new'
  get '/transaction',
      to: 'transactions#find'

  get '/proposals',
      to: 'proposals#select',
      as: 'proposals'
  post '/proposals',
       to: 'proposals#create'
  get '/proposals(/:proposal_id)',
      to: 'proposals#show',
      as: 'proposal'
  post '/proposals/(:proposal_id)/likes',
       to: 'proposals#like',
       as: 'proposal_likes'
  delete '/proposals/(:proposal_id)/likes',
         to: 'proposals#unlike'

  get '/comments/(:id)/threads',
      to: 'comments#select_threads',
      as: 'comment_threads'
  post '/comments(/:id)',
       to: 'comments#comment',
       as: 'comments'
  delete '/comments(/:id)',
         to: 'comments#delete'

  post '/comments/(:id)/likes',
       to: 'comments#like',
       as: 'comment_likes'
  delete '/comments/(:id)/likes',
         to: 'comments#unlike'
end
