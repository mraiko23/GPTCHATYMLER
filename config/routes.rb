class AdminConstraint
  def matches?(request)
    return false unless request.session[:current_admin_id].present?

    admin = Administrator.find_by(id: request.session[:current_admin_id])
    admin.present?
  end
end

Rails.application.routes.draw do
  # Routes for chats and nested messages
  resources :chats, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :messages, only: [:create, :update] do
      member do
        post :regenerate
      end
    end
  end
  # End routes for chats

  # Authentication routes - Telegram-only auth (standard auth disabled)
  delete 'sign_out', to: 'sessions#destroy', as: :sign_out
  
  # Standard authentication routes disabled for Telegram-only auth
  # get  "sign_in", to: "sessions#new"
  # post "sign_in", to: "sessions#create"
  # get  "sign_up", to: "registrations#new"
  # post "sign_up", to: "registrations#create"
  # resource :session, only: [:new, :show, :destroy] do
  #   get :devices, on: :member
  #   delete :destroy_one, on: :member
  # end
  # resources :registrations, only: [:new, :create]
  # resource  :password, only: [:edit, :update]
  #
  # namespace :identity do
  #   resource :email,              only: [:edit, :update]
  #   resource :email_verification, only: [:show, :create]
  #   resource :password_reset,     only: [:new, :edit, :create, :update]
  # end
  #
  # get  "/auth/failure",            to: "sessions/omniauth#failure"
  # get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  # post "/auth/:provider/callback", to: "sessions/omniauth#create"
  #
  # resource :invitation, only: [:new, :create]

  # Profile routes
  resource :profile, only: [:show, :edit, :update], controller: 'profiles' do
    member do
      get :edit_password
      patch :update_password
    end
  end

  # API routes - Telegram authentication only
  namespace :api do
    resources :telegram_auths, only: [:create]
    # Standard API auth disabled for Telegram-only auth
    # namespace :v1 do
    #   post 'login', to: 'sessions#login'
    #   delete 'logout', to: 'sessions#destroy'
    # end
  end

  # Authentication routes generated end

  # write your business logic routes here

  root 'home#index'

  # Do not write business logic at admin dashboard
  namespace :admin do
    resources :admin_oplogs, only: [:index, :show]
    resources :administrators
    get 'login', to: 'sessions#new', as: :login
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy', as: :logout
    resource :account, only: [:edit, :update]

    # Mount GoodJob dashboard
    mount GoodJob::Engine => 'good_job', :constraints => AdminConstraint.new

    root to: 'dashboard#index'
  end

  mount ActionCable.server => '/cable'
  match '*path', to: 'application#handle_routing_error', via: :get, constraints: lambda { |request| request.format.html? || request.format == :html }
end
