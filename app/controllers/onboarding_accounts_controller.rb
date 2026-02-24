class OnboardingAccountsController < ApplicationController
  skip_before_action :require_account
  before_action :authenticate_user!
  before_action :ensure_account_absent!
  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    ActiveRecord::Base.transaction do
      @account.save!
      current_user.update!(account: @account, role: :admin)
    end
    redirect_to root_path, notice: "Witaj na pokładzie! Konto jest gotowe."

  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(:company_name, :nip, :name)
  end

  def ensure_account_absent!
    redirect_to root_path if current_user.account.present?
  end
end
