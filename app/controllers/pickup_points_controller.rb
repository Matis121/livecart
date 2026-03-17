class PickupPointsController < ApplicationController
  before_action :set_order
  before_action :set_pickup_point

  def edit
    redirect_to @order unless turbo_frame_request?
  end

  def update
    if @pickup_point.update(pickup_point_params)
      flash.now[:notice] = "Zaktualizowano punkt odbioru"
    else
      flash.now[:error] = "Nie udało się zaktualizować punktu odbioru"
    end

    render turbo_stream: [
      turbo_stream.replace("pickup_point_section", partial: "orders/pickup_point_section", locals: { order: @order, pickup_point: @pickup_point }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  private

  def set_order
    @order = current_account.orders.find_by!(order_number: params[:order_id])
  end

  def set_pickup_point
    @pickup_point = @order.pickup_point || @order.build_pickup_point
  end

  def pickup_point_params
    params.require(:pickup_point).permit(:point_id, :name, :address_line1, :postal_code, :city)
  end
end
