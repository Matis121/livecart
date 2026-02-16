class TransmissionItemsController < ApplicationController
  before_action :set_transmission
  before_action :set_transmission_item, only: [ :show, :edit, :update, :destroy ]
  before_action :require_active_transmission, only: [ :new, :create, :bulk_create, :edit, :update, :destroy, :destroy_by_product, :destroy_by_manual ]
  before_action :set_customers, only: [ :new, :create, :bulk_create, :edit, :update, :destroy, :show ]

  def new
    @transmission_item = @transmission.transmission_items.build
  end

  def search_products
    query = params[:q].to_s.strip

    @products = if query.length >= 2
      current_account.products
        .where("name ILIKE ? OR sku ILIKE ? OR ean ILIKE ?",
               "%#{query}%", "%#{query}%", "%#{query}%")
        .limit(20)
        .order(:name)
    else
      []
    end

    render partial: "transmission_items/product_list", locals: { products: @products }
  end

  def create
    @transmission_item = @transmission.transmission_items.build(transmission_item_params)
    if @transmission_item.save
      flash.now[:notice] = "Dodano pozycję w transmisji"
      render turbo_stream: [
        turbo_stream.replace("product_items_list", partial: "transmissions/product_items_list", locals: { transmission: @transmission }),
        turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
      ]
    else
      redirect_to transmission_path(@transmission), alert: @transmission_item.errors.full_messages.join(", ")
    end
  end

  def bulk_create
    items = params[:items].to_a.reject { |h| h["customer_id"].blank? || h["quantity"].to_i < 1 }
    if items.empty?
      redirect_to transmission_path(@transmission), alert: "Dodaj co najmniej jednego klienta z ilością."
      return
    end

    product_data = resolve_product
    unless product_data
      redirect_to transmission_path(@transmission), alert: (product_error || "Wybierz produkt lub wypełnij dane produktu ręcznie.")
      return
    end

    attrs = product_data.is_a?(Hash) ? product_data : { id: product_data.id, name: product_data.name, ean: product_data.ean, sku: product_data.sku, gross_price: product_data.gross_price }

    created = 0
    errors = []
    @transmission.transaction do
      items.each do |item|
        customer = current_account.customers.find_by(id: item["customer_id"])
        next unless customer

        ti = @transmission.transmission_items.build(
          product_id: attrs[:id],
          customer_id: customer.id,
          name: attrs[:name],
          ean: attrs[:ean],
          sku: attrs[:sku],
          unit_price: attrs[:gross_price],
          quantity: item["quantity"].to_i
        )
        if ti.save
          created += 1
        else
          errors << "#{customer.name}: #{ti.errors.full_messages.join(', ')}"
        end
      end
    end

    if created.positive?
      redirect_to transmission_path(@transmission), notice: "Dodano #{created} pozycji do transmisji."
    else
      redirect_to transmission_path(@transmission), alert: errors.any? ? errors.join(" ") : "Nie udało się dodać pozycji."
    end
  end

  def edit
    render layout: false
  end

  def show
  end

  def update
    if @transmission_item.update(transmission_item_params)
      flash.now[:notice] = "Zaktualizowano pozycję transmisji"
      render turbo_stream: [
        turbo_stream.update("transmission_item_modal", ""),
        turbo_stream.replace("product_items_list", partial: "transmissions/product_items_list", locals: { transmission: @transmission }),
        turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
      ]
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transmission_item.destroy!
    flash.now[:notice] = "Usunięto pozycję transmisji"
          render turbo_stream: [
        turbo_stream.replace("product_items_list", partial: "transmissions/product_items_list", locals: { transmission: @transmission }),
        turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
      ]
  end

  def destroy_by_product
    product_id = params[:product_id].presence
    unless product_id.present?
      redirect_to transmission_path(@transmission), alert: "Brak produktu."
      return
    end
    count = @transmission.transmission_items.where(product_id: product_id).destroy_all.size
    redirect_to transmission_path(@transmission), notice: "Usunięto #{count} #{count == 1 ? 'pozycję' : 'pozycji'} dla produktu."
  end

  def destroy_by_manual
    name = params[:name].to_s.strip
    if name.blank?
      redirect_to transmission_path(@transmission), alert: "Brak nazwy."
      return
    end
    scope = @transmission.transmission_items.where(product_id: nil, name: name)
    scope = scope.where(sku: params[:sku].to_s.presence) # pusty sku w URL => dopasuj sku: nil
    count = scope.destroy_all.size
    redirect_to transmission_path(@transmission), notice: "Usunięto #{count} #{count == 1 ? 'pozycję' : 'pozycji'}."
  end

  private

  def resolve_product
    if params[:product_source].to_s == "manual"
      create_manual_product
    else
      product_id = params[:product_id].presence
      return nil if product_id.blank?
      current_account.products.find_by(id: product_id)
    end
  end

  def product_error
    @product_error
  end

  def create_manual_product
    manual = params.fetch(:manual_product, {}).permit(:name, :sku, :ean, :gross_price, :tax_rate).to_h
    name = manual["name"].to_s.strip
    gross_price = manual["gross_price"].to_s.gsub(",", ".").presence

    if name.blank?
      @product_error = "Podaj nazwę produktu."
      return nil
    end
    if gross_price.blank? || gross_price.to_f.negative?
      @product_error = "Podaj prawidłową cenę brutto."
      return nil
    end

    # Nie tworzymy produktu w magazynie — tylko dane do pozycji transmisji (hash)
    {
      id: nil,
      name: name,
      sku: manual["sku"].presence,
      ean: manual["ean"].presence,
      gross_price: gross_price.to_f
    }
  end

  def set_transmission
    @transmission = current_account.transmissions.find(params[:transmission_id])
  end

  def set_transmission_item
    @transmission_item = @transmission.transmission_items.find(params[:id])
  end

  def set_customers
    @customers = current_account.customers.order(:first_name, :last_name)
  end

  def require_active_transmission
    unless @transmission.active?
      redirect_to transmission_path(@transmission), alert: "Nie można modyfikować pozycji zakończonej transmisji."
    end
  end

  def transmission_item_params
    params.require(:transmission_item).permit(:product_id, :customer_id, :name, :ean, :sku, :unit_price, :quantity)
  end
end
