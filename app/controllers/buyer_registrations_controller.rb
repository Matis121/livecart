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
    email = params[:email].to_s.strip

    # Already registered with this username — redirect as success
    existing_pa = CustomerPlatformAccount.find_by(
      account_id: @shop.id, platform: "tiktok", platform_username: username
    )
    if existing_pa
      redirect_to new_buyer_registration_path(shop_slug: @shop.slug, registered: username)
      return
    end

    ActiveRecord::Base.transaction do
      customer = @shop.customers.find_by(email: email.presence) ||
                 @shop.customers.build(email: email.presence, phone: phone)

      if customer.new_record? && !customer.save
        @customer = customer
        raise ActiveRecord::Rollback
      end

      pa = customer.platform_accounts.build(
        account_id: @shop.id,
        platform: "tiktok",
        platform_username: username
      )

      if pa.save
        redirect_to new_buyer_registration_path(shop_slug: @shop.slug, registered: username)
      else
        @customer = customer
        pa.errors.each { |e| @customer.errors.add(e.attribute, e.message) }
        raise ActiveRecord::Rollback
      end
    end

    render :new, status: :unprocessable_entity if @customer.present? && @customer.errors.any?
  end

  private

  def find_shop
    @shop = Account.find_by!(slug: params[:shop_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to not_found_checkouts_path
  end
end
