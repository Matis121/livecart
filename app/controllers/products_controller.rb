require "csv"

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
      # 1. Usuwanie zdjęć
      if params[:product][:images_to_delete].present?
        images_to_delete = @product.images.where(id: params[:product][:images_to_delete])
        images_to_delete.each(&:purge)
      end

      # 2. Korekta stanu
      if params[:product][:stock_quantity].present?
        @product.product_stock.adjust_quantity!(params[:product][:stock_quantity].to_i)
      end

      # 3. Dodaj nowe zdjęcia (zamiast zastępowania)
      update_params = product_params.except(:images_to_delete, :stock_quantity)
      if update_params[:images].present?
        @product.images.attach(update_params[:images])
        update_params = update_params.except(:images)
      end

      # 4. Aktualizacja reszty
      if @product.update(update_params)
        redirect_to products_path, notice: "Zaktualizowano produkt"
      else
        raise ActiveRecord::Rollback
      end
    end

    render :edit, status: :unprocessable_entity unless performed?
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
      if count <= 10
        # Sync delete for small batches
        products.destroy_all
        redirect_to products_path, notice: "Usunięto #{flash_message}"
      else
        # Async delete for larger batches
        Products::BulkDeleteJob.perform_later(current_account.id, product_ids)
        redirect_to products_path, notice: "Usuwanie #{flash_message} w toku. Sprawdź logi Sidekiq."
      end
    when "export"
      products.includes(:product_stock, images_attachments: :blob)

      csv_data = Products::CsvExporter.call(products)

      send_data csv_data,
                filename: "produkty_#{Date.current.strftime('%Y%m%d')}.csv",
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    else
      redirect_to products_path, alert: "Nieznana akcja"
    end
  end

  def import_form
  end

  def import_history
    @q = current_account.product_imports.ransack(params[:q])
    imports = @q.result.order(created_at: :desc)
    @pagy, @product_imports = pagy(imports, limit: 10)
  end

  def import
    unless params[:csv_file].present?
      redirect_to import_form_products_path, alert: "Nie wybrano pliku CSV"
      return
    end

    unless params[:duplicate_strategy].present?
      redirect_to import_form_products_path, alert: "Nie wybrano strategii duplikatów"
      return
    end

    result = Products::ImportCoordinator.new(
      account: current_account,
      csv_file: params[:csv_file],
      duplicate_strategy: params[:duplicate_strategy]
    ).call

    redirect_to products_path, notice: result[:message]
  rescue Products::ImportCoordinator::ValidationError => e
    redirect_to import_form_products_path, alert: e.message
  rescue StandardError => e
    redirect_to import_form_products_path, alert: "Błąd importu: #{e.message}"
  end

  private

  def set_product
    @product = current_account.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :sku, :ean, :gross_price, :tax_rate, :quantity, :currency,
      :baselinker_product_id,
      images: [],
      product_stock_attributes: [ :id, :quantity ]
    )
  end
end
