class IntegrationsController < ApplicationController
  before_action :set_integration, only: [ :show, :edit, :update, :destroy, :sync_now ]

  def index
    @integrations = current_account.integrations
                                   .includes(:user)
                                   .order(created_at: :desc)

    # Group by integration type for better organization
    @integrations_by_type = @integrations.group_by(&:integration_type)
  end

  def show
    # Show integration details and sync logs
  end

  def new
    @integration = current_account.integrations.new

    # Pre-populate provider if coming from tile selection
    if params[:provider].present?
      @integration.provider = params[:provider]
      @integration.integration_type = Integration.integration_type_for_provider(params[:provider])
    end
  end

  def create
    @integration = current_account.integrations.new(integration_params)
    @integration.user = current_user
    @integration.status = "active"

    # Auto-detect integration_type from provider
    @integration.integration_type = Integration.integration_type_for_provider(@integration.provider)

    if @integration.save
      redirect_to integrations_path, notice: "Integracja została pomyślnie dodana."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    params_to_update = integration_params
    params_to_update = params_to_update.except(:api_key) if params_to_update[:api_key].blank?
    params_to_update = params_to_update.except(:api_secret) if params_to_update[:api_secret].blank?

    if @integration.update(params_to_update)
      redirect_to integrations_path, notice: "Integracja została zaktualizowana."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration.destroy
    redirect_to integrations_path, notice: "Integracja została usunięta."
  end

  def sync_now
    # Manual sync trigger
    case @integration.provider
    when "baselinker"
      Integrations::BaselinkerSyncJob.perform_later(@integration.id)
      message = "Synchronizacja Baselinker została uruchomiona."
    when "sellasist"
      Integrations::SellasistSyncJob.perform_later(@integration.id)
      message = "Synchronizacja Sellasist została uruchomiona."
    else
      message = "Synchronizacja dla tego providera nie jest jeszcze dostępna."
    end

    redirect_to integrations_path, notice: message
  end

  private

  def set_integration
    @integration = current_account.integrations.find(params[:id])
  end

  def integration_params
    params.require(:integration).permit(
      :provider,
      :provider_account_name,
      :api_key,
      :api_secret,
      :access_token,
      :refresh_token,
      :status,
      settings: [ :inventory_id, :stock_sync_enabled, :price_sync_enabled,
                  :stock_match_by, :price_match_by, :export_order_status,
                  :baselinker_status_id, :order_status_sync_enabled,
                  :custom_source_id, { status_mapping: {} } ]
    )
  end
end
