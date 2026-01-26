module Settings
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    def index
      @active_tab = params[:tab] || "all"
    end
  end
end
