Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  resources :onboarding_accounts, only: [ :new, :create ]
  resources :products, controller: "products"
  resources :product_reservations, only: [ :index ]
  resources :customers, controller: "customers"
  resources :orders, controller: "orders" do
    resources :order_items, only: [ :new, :create, :edit, :update, :destroy ] do
      post :quick_add, on: :collection
    end
    resource :shipping_address, only: [ :edit, :update ] do
      patch :copy_from_billing
    end
    resource :billing_address, only: [ :edit, :update ] do
      patch :copy_from_shipping
    end
    member do
      get :edit_customer
      get :edit_contact_info
      patch :update_contact_info
      get :edit_payment
      patch :update_payment
      get :edit_shipping_payment_methods
      patch :update_shipping_payment_methods
      patch :update_status
      get :status_history
      get :activate_checkout
      get :cancel_checkout
    end
  end

  root "dashboard#index"

  # Checkout
  resources :checkouts, only: [ :show, :update ]
end
