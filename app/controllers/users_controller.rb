class UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [ :update, :destroy ]

  def index
    @users = current_account.users.order(created_at: :asc)
  end

  def new
    @user = User.new
  end

  def create
    @user = current_account.users.build(user_params)

    if @user.save
      redirect_to employees_path, notice: "Pracownik został utworzony"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to employees_path, notice: "Pracownik został zaktualizowany"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.admin?
      redirect_to employees_path, alert: "Nie można usunąć administratora"
      return
    end

    @user.destroy
    redirect_to employees_path, notice: "Pracownik został usunięty"
  end

  private

  def set_user
    @user = current_account.users.find(params[:id])
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Brak uprawnień"
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
