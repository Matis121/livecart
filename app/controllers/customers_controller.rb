class CustomersController < ApplicationController
  before_action :set_customer, only: [ :edit, :update, :destroy ]

  PER_PAGE_OPTIONS = [ 10, 20, 35, 50, 100, 250 ].freeze
  DEFAULT_PER_PAGE = 10
  def index
    @customers = current_account.customers.order(created_at: :asc)

    per_page = if params[:per_page].present?
      params[:per_page].to_i
    elsif cookies[:customers_per_page].present?
      cookies[:customers_per_page].to_i
    else
      DEFAULT_PER_PAGE
    end

    per_page = DEFAULT_PER_PAGE unless PER_PAGE_OPTIONS.include?(per_page)
    cookies[:customers_per_page] = { value: per_page, expires: 1.year.from_now }

    @per_page_options = PER_PAGE_OPTIONS
    @pagy, @customers = pagy(@customers, limit: per_page)
  end

  def edit
    redirect_to customers_path unless turbo_frame_request?
  end

  def new
    redirect_to customers_path unless turbo_frame_request?

    @customer = Customer.new
  end

  def create
    @customer = current_account.customers.build(customer_params)
    if @customer.save
      redirect_to customers_path, notice: "Utworzono klienta"
    else
      render turbo_stream: turbo_stream.replace("customer_modal", template: "customers/new")
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: "Zaktualizowano klienta"
    else
      render turbo_stream: turbo_stream.replace("customer_modal", template: "customers/edit")
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "Usunięto klienta"
  end

  private

  def set_customer
    @customer = current_account.customers.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :platform_user_id, :platform, :platform_username, :profile_data)
  end
end
