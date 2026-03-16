module DashboardHelper
  STATUS_LABELS = {
    "draft"              => "Szkic",
    "open_package"       => "Otwarta paczka",
    "offer_sent"         => "Oferta wysłana",
    "payment_processing" => "Płatność w trakcie",
    "in_fulfillment"     => "Do realizacji",
    "shipped"            => "Wysłane",
    "delivered"          => "Zrealizowane",
    "cancelled"          => "Anulowane",
    "returned"           => "Zwrócone"
  }.freeze

  STATUS_BADGE_CSS = {
    "paid"               => "badge-success",
    "delivered"          => "badge-success",
    "shipped"            => "badge-info",
    "offer_sent"         => "badge-info",
    "payment_processing" => "badge-warning",
    "in_fulfillment"     => "badge-warning",
    "open_package"       => "badge-warning",
    "cancelled"          => "badge-error",
    "returned"           => "badge-error",
    "draft"              => "badge-ghost"
  }.freeze

  STATUS_BAR_CSS = {
    "paid"               => "bg-success",
    "delivered"          => "bg-success",
    "shipped"            => "bg-info",
    "offer_sent"         => "bg-info",
    "payment_processing" => "bg-warning",
    "in_fulfillment"     => "bg-warning",
    "open_package"       => "bg-warning",
    "cancelled"          => "bg-error",
    "returned"           => "bg-error",
    "draft"              => "bg-base-300"
  }.freeze

  def dashboard_status_badge(status)
    label = STATUS_LABELS[status.to_s] || status.to_s.humanize
    css   = STATUS_BADGE_CSS[status.to_s] || "badge-ghost"
    [ label, css ]
  end

  def dashboard_status_bar_color(status)
    STATUS_BAR_CSS[status.to_s] || "bg-base-300"
  end
end
