class TransmissionsController < ApplicationController
  before_action :set_transmission, only: [ :show, :edit, :update, :destroy, :convert_to_orders ]

  PER_PAGE_OPTIONS = [ 10, 20, 35, 50, 100, 250 ].freeze
  DEFAULT_PER_PAGE = 10

  def index
    transmissions = current_account.transmissions.order(created_at: :desc)

    per_page = if params[:per_page].present?
      params[:per_page].to_i
    elsif cookies[:transmissions_per_page].present?
      cookies[:transmissions_per_page].to_i
    else
      DEFAULT_PER_PAGE
    end

    per_page = DEFAULT_PER_PAGE unless PER_PAGE_OPTIONS.include?(per_page)
    cookies[:transmissions_per_page] = { value: per_page, expires: 1.year.from_now }

    @per_page_options = PER_PAGE_OPTIONS
    @pagy, @transmissions = pagy(transmissions, limit: per_page)

    transmission_ids = @transmissions.map(&:id)
    @expected_orders_counts = TransmissionItem
      .where(transmission_id: transmission_ids)
      .group(:transmission_id)
      .distinct
      .count(:customer_id)
    @created_orders_counts = Order
      .where(transmission_id: transmission_ids)
      .group(:transmission_id)
      .count
  end

  def show
    @customers = current_account.customers
    @products = current_account.products
  end

  def new
    redirect_to transmissions_path unless turbo_frame_request?

    @transmission = Transmission.new
  end

  def create
    @transmission = current_account.transmissions.build(transmission_params)
    @transmission.status = :active
    if @transmission.save
      redirect_to transmission_path(@transmission), notice: "Utworzono transmisję"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @transmission unless turbo_frame_request?
  end

  def update
    if @transmission.update(transmission_params)
      redirect_to transmission_path(@transmission), notice: "Zaktualizowano transmisję"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transmission.destroy!
    redirect_to transmissions_path, notice: "Usunięto transmisję"
  end

  def convert_to_orders
    # Walidacja - czy można zamknąć?
    if @transmission.completed? || @transmission.cancelled?
      redirect_to @transmission, alert: "Transmisja już jest zamknięta"
      return
    end

    if @transmission.processing?
      redirect_to @transmission, alert: "Transmisja jest w trakcie przetwarzania"
      return
    end

    if @transmission.transmission_items.empty?
      redirect_to @transmission, alert: "Nie można zamknąć pustej transmisji - dodaj produkty i klientów"
      return
    end

    # Uruchom job w tle
    TransmissionConverterJob.perform_later(@transmission.id)

    redirect_to @transmission,
                notice: "Przetwarzanie rozpoczęte!"
  end

  private

  def transmission_params
    params.require(:transmission).permit(:name, :status)
  end

  def set_transmission
    @transmission = current_account.transmissions.find(params[:id])
  end
end
