module CheckoutsHelper
  def checkout_status_badge(checkout)
    if checkout.available?
      content_tag :span, class: "badge badge-success gap-1" do
        lucide_icon("check-circle", class: "w-3 h-3") + " Aktywny"
      end
    elsif checkout.expired?
      content_tag :span, class: "badge badge-error gap-1" do
        lucide_icon("clock", class: "w-3 h-3") + " Wygasły"
      end
    elsif checkout.completed?
      content_tag :span, class: "badge badge-info gap-1" do
        lucide_icon("check", class: "w-3 h-3") + " Ukończony"
      end
    else
      content_tag :span, class: "badge badge-ghost gap-1" do
        lucide_icon("x-circle", class: "w-3 h-3") + " Nieaktywny"
      end
    end
  end
  
  def checkout_expiry_info(checkout)
    return nil unless checkout.expires_at.present?
    
    content_tag :span, class: "text-xs text-base-content/60" do
      "Wygasa: #{checkout.expires_at.strftime('%d.%m.%Y %H:%M')}"
    end
  end
end
