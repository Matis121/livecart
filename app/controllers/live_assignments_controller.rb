class LiveAssignmentsController < ApplicationController
  before_action :set_transmission
  before_action :require_active_transmission

  # GET /transmissions/:transmission_id/live_assignments/new_assignment
  # Opens modal with pre-filled TikTok user data
  def new_assignment
    @platform   = params[:platform].to_s
    @user_id    = params[:user_id].to_s
    @username   = params[:username].to_s
    @avatar_url = params[:avatar_url].to_s

    # Pre-build customer if they already exist
    @customer = current_account.customers.find_by(
      platform: @platform,
      platform_user_id: @user_id
    ) || current_account.customers.new(
      platform:          @platform,
      platform_user_id:  @user_id,
      platform_username: @username,
      first_name:        @username,
      last_name:         "-"
    )

    @products = []

    render layout: false
  end

  # POST /transmissions/:transmission_id/live_assignments
  def create
    platform   = params[:platform].to_s
    user_id    = params[:user_id].to_s
    username   = params[:username].to_s
    avatar_url = params[:avatar_url].to_s
    product_id = params[:product_id].presence
    quantity   = params[:quantity].to_i.clamp(1, 9999)
    unit_price = params[:unit_price].to_s.gsub(",", ".").to_f

    product = current_account.products.find_by(id: product_id)
    unless product
      render turbo_stream: turbo_stream.update("flash_messages",
        partial: "layouts/flash_messages",
        locals: { flash: { alert: "Nie znaleziono produktu." } })
      return
    end

    customer = Customer.find_or_create_from_platform(
      current_account,
      platform:    platform,
      user_id:     user_id,
      username:    username,
      profile_data: { avatar_url: avatar_url }
    )

    # Override first/last name if provided in form
    if params[:first_name].present? || params[:last_name].present?
      customer.update!(
        first_name: params[:first_name].presence || customer.first_name,
        last_name:  params[:last_name].presence  || customer.last_name
      )
    end

    transmission_item = @transmission.transmission_items.build(
      customer:   customer,
      product:    product,
      name:       product.name,
      ean:        product.ean,
      sku:        product.sku,
      unit_price: unit_price.positive? ? unit_price : product.gross_price,
      quantity:   quantity
    )

    if transmission_item.save
      flash.now[:notice] = "Dodano #{customer.name} → #{product.name}"
      render turbo_stream: [
        turbo_stream.update("live_assignment_modal", ""),
        turbo_stream.replace("product_items_list",
          partial: "transmissions/product_items_list",
          locals:  { transmission: @transmission }),
        turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
      ]
    else
      flash.now[:alert] = transmission_item.errors.full_messages.join(", ")
      render turbo_stream: turbo_stream.update("flash_messages", partial: "layouts/flash_messages"),
             status: :unprocessable_entity
    end
  end

  private

  def set_transmission
    @transmission = current_account.transmissions.find(params[:transmission_id])
  end

  def require_active_transmission
    unless @transmission.active?
      head :unprocessable_entity
    end
  end
end
