module Settings
  class TermsController < ApplicationController
    before_action :authenticate_user!
    def edit
      @account = current_account
      @terms = @account.terms || {}
    end

    def update
      @account = current_account
      if @account.update(terms_params)
        redirect_to settings_terms_path, notice: "Ustawienia zostały zaktualizowane"
      else
        @terms = @account.terms || {}
        render :edit
      end
    end

    private

    def terms_params
      params.require(:account).permit(:terms_content, :privacy_policy_content)
    end
  end
end
