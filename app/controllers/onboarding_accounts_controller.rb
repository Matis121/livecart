class OnboardingAccountsController < ApplicationController
  skip_before_action :require_account
  before_action :authenticate_user!
  before_action :ensure_account_absent!
  def new
    @account = Account.new
  end

  def create
    ActiveRecord::Base.transaction do
      account = Account.create!(account_params)
      current_user.update!(account: account, role: :admin)
    end
    redirect_to root_path, notice: "Witaj na pokładzie! Konto jest gotowe."

  rescue ActiveRecord::RecordInvalid
    @account = Account.new(account_params)
    render :new, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(:company_name, :nip)
  end

  def ensure_account_absent!
    redirect_to root_path if current_user.account.present?
  end
end
