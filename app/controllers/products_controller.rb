class ProductsController < ApplicationController
  PER_PAGE_OPTIONS = [ 10, 20, 35, 50, 100, 250 ].freeze
  DEFAULT_PER_PAGE = 10

  before_action :set_product, only: [ :show, :edit, :update ]

  def index
    @all_products = current_account.products
    @q = @all_products.ransack(params[:q])
    products = @q.result.includes(:product_stock).order(created_at: :desc)

    # Pobierz per_page: najpierw z params, potem z cookies, na końcu default
    per_page = if params[:per_page].present?
      params[:per_page].to_i
    elsif cookies[:products_per_page].present?
      cookies[:products_per_page].to_i
    else
      DEFAULT_PER_PAGE
    end

    per_page = DEFAULT_PER_PAGE unless PER_PAGE_OPTIONS.include?(per_page)

    # Zapisz do cookies (na 1 rok)
    cookies[:products_per_page] = { value: per_page, expires: 1.year.from_now }

    @per_page_options = PER_PAGE_OPTIONS
    @pagy, @products = pagy(products, limit: per_page)
  end

  def show
  end

  def new
    @product = Product.new
    @product.build_product_stock
  end

  def create
    @product = current_account.products.build(product_params)
    if @product.save
      redirect_to products_path, notice: "Utworzono produkt"
    else
      render :new
    end
  end

  def update
    Product.transaction do
      # 1. Usuwanie zdjęć (bezpieczniej w transakcji)
      if params[:product][:images_to_delete].present?
        @product.images.where(id: params[:product][:images_to_delete]).purge
      end

      # 2. Korekta stanu
      if params[:product][:stock_quantity].present?
        @product.product_stock.adjust_quantity!(params[:product][:stock_quantity].to_i)
      end

      # 3. Aktualizacja reszty (w tym nowych obrazów, jeśli używasz attach)
      if @product.update(product_params.except(:images_to_delete, :stock_quantity))
        redirect_to products_path, notice: "Zaktualizowano produkt"
      else
        raise ActiveRecord::Rollback
      end
    end

    render :edit unless performed?
  end

  def edit
    @product.build_product_stock unless @product.product_stock
  end

  def destroy
    @product = current_account.products.find(params[:id])

    if @product.destroy
      redirect_to products_path, notice: "Usunięto produkt"
    else
      redirect_to products_path, alert: "Nie udało się usunąć produktu"
    end
  end


  def bulk_action
    product_ids = params[:product_ids] || []
    action_type = params[:action_type]

    if product_ids.empty?
      redirect_to products_path, alert: "Nie wybrano żadnych produktów"
      return
    end

    # Znajdź produkty należące do current_account
    products = current_account.products.where(id: product_ids)

    count = products.count
    flash_message = count == 1 ? "produkt id #{products.first.id}" : "produkty"

    case action_type
    when "delete"
      products.destroy_all
      redirect_to products_path, notice: "Usunięto #{flash_message}"

    else
      redirect_to products_path, alert: "Nieznana akcja"
    end
  end

  private

  def set_product
    @product = current_account.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :sku, :ean, :gross_price, :tax_rate, :quantity, :currency, images: [], product_stock_attributes: [ :id, :quantity ])
  end
end
