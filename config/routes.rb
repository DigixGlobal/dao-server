# frozen_string_literal: true

Rails.application.routes.draw do
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

  post '/proposals',
       to: 'proposals#create',
       as: 'proposals'
  get '/proposals/(:id)',
      to: 'proposals#show',
      as: 'proposal'
  post '/proposals/(:id)/likes',
       to: 'proposals#like',
       as: 'proposal_likes'
  delete '/proposals/(:id)/likes',
         to: 'proposals#unlike'

  get '/comments/(:id)/threads',
      to: 'comments#select_threads',
      as: 'comments'
  post '/comments(/:id)',
       to: 'comments#comment'
  delete '/comments(/:id)',
         to: 'comments#delete'

  post '/comments/(:id)/likes',
       to: 'comments#like',
       as: 'comment_likes'
  delete '/comments/(:id)/likes',
         to: 'comments#unlike'
end
