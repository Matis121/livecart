require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"


  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  resources :onboarding_accounts, only: [ :new, :create ]
  resources :products, controller: "products" do
    collection do
      post :bulk_action
      patch :bulk_action
      get :import_form
      post :import
      get :import_history
    end
  end
  namespace :settings do
    root to: "dashboard#index"

    resource :checkout, only: [ :edit, :update ], controller: "checkout"
    resource :terms, only: [ :edit, :update ], controller: "terms"
    resources :discounts, only: [ :index, :new, :create, :update, :destroy ]
    resources :shipping_methods, only: [ :index, :new, :create, :edit, :update, :destroy ], controller: "shipping_methods"
    resources :payment_methods, only: [ :index, :new, :create, :edit, :update, :destroy ], controller: "payment_methods"
  end
  resources :customers, controller: "customers"
  resources :employees, controller: "users"
  resources :orders, controller: "orders" do
    collection do
      patch :bulk_action
    end
    resources :order_items, only: [ :new, :create, :edit, :update, :destroy ] do
       collection do
          post :quick_add
          get :search_products
       end
    end
    resource :shipping_address, only: [ :edit, :update ] do
      patch :copy_from_billing
    end
    resource :billing_address, only: [ :edit, :update ] do
      patch :copy_from_shipping
    end
    member do
      get :edit_customer
      get :edit_discount_code
      patch :update_discount_code
      get :edit_contact_info
      patch :update_contact_info
      get :edit_payment
      patch :update_payment
      get :edit_shipping_payment_methods
      patch :update_shipping_payment_methods
      patch :update_status
      get :status_history
      post :activate_checkout
      delete :cancel_checkout
    end
  end

  resources :transmissions, controller: "transmissions" do
    member do
      post :convert_to_orders
    end
    resources :transmission_items, only: [ :new, :create, :show, :edit, :update, :destroy ] do
      collection do
        post :bulk_create
        delete :destroy_by_product
        delete :destroy_by_manual
        get :search_products
      end
    end
  end

  # Integrations
  resources :integrations do
    member do
      post :sync_now
    end
  end

  root "dashboard#index"

  # Checkout
  get "checkouts/not_found", to: "checkouts#not_found", as: :not_found_checkouts

  scope "/shops/:shop_slug" do
    resources :checkouts, only: [ :show, :update ] do
      member do
        patch :close_package
      end
    end
  end
end
