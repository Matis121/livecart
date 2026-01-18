class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]
  def index
    @products = current_account.products.order(created_at: :asc)
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
      redirect_to products_path, notice: "Produkt został utworzony"
    else
      render :new
    end
  end

  def update
    if params[:product][:images_to_delete].present?
      @product.images.where(id: params[:product][:images_to_delete]).each(&:purge)
    end

    if params[:product][:images].present?
      @product.images.attach(params[:product][:images])
    end

    if @product.update(product_params.except(:images_to_delete, :images))
      redirect_to products_path, notice: "Produkt został zaktualizowany"
    else
      render :edit
    end
  end

  def edit
    @product.build_product_stock unless @product.product_stock
    @product.product_stock.quantity = @product.product_stock.quantity - @product.product_stock.reserved_quantity
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Produkt został usunięty"
  end

  private

  def set_product
    @product = current_account.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :sku, :ean, :gross_price, :tax_rate, :quantity, :currency, images: [], product_stock_attributes: [ :id, :quantity ])
  end
end
