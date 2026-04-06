class CustomersController < ApplicationController
  before_action :set_customer, only: [ :edit, :update, :destroy ]

  PER_PAGE_OPTIONS = [ 10, 20, 35, 50, 100, 250 ].freeze
  DEFAULT_PER_PAGE = 10
  def index
    @all_customers = current_account.customers

    case params[:platform]
    when "tiktok"
      @all_customers = @all_customers.joins(:platform_accounts)
                                     .where(customer_platform_accounts: { platform: "tiktok" })
    when "manual"
      @all_customers = @all_customers.left_joins(:platform_accounts)
                                     .where(customer_platform_accounts: { id: nil })
    end

    @q = @all_customers.ransack(params[:q])
    # Deduplicate via subquery on id to avoid DISTINCT on json columns (profile_data)
    distinct_ids = @q.result.select("customers.id")
    @customers = Customer.where(id: distinct_ids).order(created_at: :desc).includes(:platform_accounts)

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
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = current_account.customers.build(customer_params)
    if @customer.save
      redirect_to customers_path, notice: "Utworzono klienta"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: "Zaktualizowano klienta"
    else
      render :edit, status: :unprocessable_entity
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
    permitted = params.require(:customer).permit(
      :first_name, :last_name, :email, :phone_prefix, :phone_number, :platform, :platform_username,
      :shipping_first_name, :shipping_last_name, :shipping_address_line1, :shipping_address_line2,
      :shipping_city, :shipping_postal_code, :shipping_country,
      :billing_needs_invoice, :billing_company_name, :billing_nip,
      :billing_first_name, :billing_last_name, :billing_address_line1, :billing_address_line2,
      :billing_city, :billing_postal_code, :billing_country
    )
    prefix = permitted.delete(:phone_prefix).to_s.strip
    number = permitted.delete(:phone_number).to_s.gsub(/\D/, "")
    permitted[:phone] = number.present? ? "#{prefix}#{number}" : nil
    permitted[:platform] = permitted[:platform].presence
    permitted
  end
end
