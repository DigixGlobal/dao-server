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

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # get '/test', to: "proposals#test"
  get '/user/details', to: 'user#details'
  post '/user/new', to: 'user#new_user'
  # get '/token', to: "proposals#test_token"
  get '/get_challenge', to: 'authentication#challenge'
  post '/prove', to: 'authentication#prove'

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
  post '/proposals/(:id)/comments',
       to: 'proposals#comment',
       as: 'proposal_comments'
  post '/comments/(:id)',
       to: 'proposals#reply',
       as: 'comment'
  delete '/comments/(:id)',
         to: 'proposals#delete_comment'

  post '/comments/(:id)/likes',
       to: 'comments#like',
       as: 'comment_likes'
  delete '/comments/(:id)/likes',
         to: 'comments#unlike'
end
