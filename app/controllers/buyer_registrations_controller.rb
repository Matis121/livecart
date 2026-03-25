class BuyerRegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_account

  before_action :find_shop

  def new
    @customer = Customer.new
  end

  def create
    username = params[:tiktok_username].to_s.delete_prefix("@").strip
    phone_prefix = params[:phone_prefix].to_s.strip
    phone_number = params[:phone_number].to_s.gsub(/\D/, "")
    phone = phone_number.present? ? "#{phone_prefix}#{phone_number}" : nil
    @customer = @shop.customers.new(
      platform: "tiktok",
      platform_username: username,
      email: params[:email].to_s.strip,
      phone: phone
    )

    if @customer.save
      redirect_to new_buyer_registration_path(shop_slug: @shop.slug, registered: username)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_shop
    @shop = Account.find_by!(slug: params[:shop_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to not_found_checkouts_path
  end
end
